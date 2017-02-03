import os
from enum import Enum
from datetime import datetime, timedelta

import psycopg2

from psycopg2.extras import DateTimeTZRange
from psycopg2.extensions import adapt as psyco_adapt

from jinja2 import Environment, FileSystemLoader
from dateutil import parser as date_parser
from mx.DateTime import DateTimeDeltaFrom

from settings import DATABASE, DB_USER, DO_ENABLE_RESTRICTIONS, DB_PASSWORD

from db_helpers import get_attribute_fields, get_attribute_names
from db_helpers import get_field_type, get_state_names, get_relation_field_type
from db_helpers import (Soegeord, OffentlighedUndtaget, JournalNotat,
                        JournalDokument, DokumentVariantType, AktoerAttr,
                        VaerdiRelationAttr)

from authentication import get_authenticated_user

from auth.restrictions import Operation, get_restrictions
from utils.build_registration import restriction_to_registration
from custom_exceptions import NotFoundException, NotAllowedException
from custom_exceptions import DBException, BadRequestException

"""
    Jinja2 Environment
"""

current_directory = os.path.dirname(os.path.realpath(__file__))

jinja_env = Environment(loader=FileSystemLoader(
    os.path.join(current_directory, 'templates', 'sql')
))


def adapt(value):
    adapter = psyco_adapt(value)
    if hasattr(adapter, 'prepare'):
        adapter.prepare(adapt_connection)
    return unicode(adapter.getquoted(), adapt_connection.encoding)


jinja_env.filters['adapt'] = adapt

"""
    GENERAL FUNCTION AND CLASS DEFINITIONS
"""


def get_connection():
    """Handle all intricacies of connecting to Postgres."""
    connection = psycopg2.connect(
        "dbname={0} user={1} password={2}".format(DATABASE,
                                                  DB_USER,
                                                  DB_PASSWORD)
    )
    connection.autocommit = True
    return connection


adapt_connection = get_connection()


def convert_attr_value(attribute_name, attribute_field_name,
                       attribute_field_value):
    # For simple types that can be adapted by standard psycopg2 adapters, just
    # pass on. For complex types like "Soegeord" with specialized adapters,
    # convert to the class for which the adapter is registered.
    field_type = get_field_type(attribute_name, attribute_field_name)
    if field_type == "soegeord":
        return [Soegeord(*ord) for ord in attribute_field_value]
    elif field_type == "offentlighedundtagettype":
        if not ('alternativtitel' in attribute_field_value) and not (
                'hjemmel' in attribute_field_value):
            # Empty object, so provide the DB with a NULL, so that the old
            # value is not overwritten.
            return None
        else:
            return OffentlighedUndtaget(
                attribute_field_value.get('alternativtitel', None),
                attribute_field_value.get('hjemmel', None))
    elif field_type == "date":
        return datetime.strptime(attribute_field_value, "%Y-%m-%d").date()
    elif field_type == "timestamptz":
        return date_parser.parse(attribute_field_value)
    elif field_type == "interval(0)":
        return DateTimeDeltaFrom(attribute_field_value).pytimedelta()
    else:
        return attribute_field_value


def convert_relation_value(class_name, field_name, value):
    field_type = get_relation_field_type(class_name, field_name)
    if field_type == "journalnotat":
        return JournalNotat(value.get("titel", None), value.get("notat", None),
                            value.get("format", None))
    elif field_type == "journaldokument":
        ou = value.get("offentlighedundtaget", {})
        return JournalDokument(
            value.get("dokumenttitel", None),
            OffentlighedUndtaget(ou.get('alternativtitel', None),
                                 ou.get('hjemmel', None))
        )
    elif field_type == 'aktoerattr':
        if value:
            return AktoerAttr(value.get("accepteret", None),
                value.get("obligatorisk", None),
                value.get("repraesentation_uuid", None),
                value.get("repraesentation_urn", None))
    elif field_type == 'vaerdirelationattr':
        result = VaerdiRelationAttr(
                     value.get("forventet", None),
                     value.get("nominelvaerdi", None)
        )
        return result
    # Default: no conversion. 
    return value


def convert_attributes(attributes):
    "Convert attributes from dictionary to list in correct order."
    if attributes:
        for attr_name in attributes:
            current_attr_periods = attributes[attr_name]
            converted_attr_periods = []
            for attr_period in current_attr_periods:
                field_names = get_attribute_fields(attr_name)
                attr_value_list = [
                    convert_attr_value(
                        attr_name, f, attr_period[f]
                    ) if f in attr_period else None
                    for f in field_names
                    ]
                converted_attr_periods.append(attr_value_list)
            attributes[attr_name] = converted_attr_periods
    return attributes


def convert_relations(relations, class_name):
    "Convert relations - i.e., convert each field according to its type"
    if relations:
        for rel_name in relations:
            periods = relations[rel_name]
            for period in periods:
                if not isinstance(period, dict):
                    raise BadRequestException(
                        'mapping expected for "%s" in "%s" - got %r' %
                        (period, rel_name, period)
                    )
                for field in period:
                    converted = convert_relation_value(
                        class_name, field, period[field]
                    )
                    period[field] = converted
    return relations


def convert_variants(variants):
    """Convert variants."""
    # TODO
    if variants is None:
        return None
    return [DokumentVariantType.input(variant) for variant in variants]


class Livscyklus(Enum):
    OPSTAAET = 'Opstaaet'
    IMPORTERET = 'Importeret'
    PASSIVERET = 'Passiveret'
    SLETTET = 'Slettet'
    RETTET = 'Rettet'


"""
    GENERAL SQL GENERATION.

    All of these functions generate bits of SQL to use in complete statements.
    At some point, we might want to factor them to an "sql_helpers.py" module.
"""


def sql_state_array(state, periods, class_name):
    """Return an SQL array of type <state>TilsType."""
    t = jinja_env.get_template('state_array.sql')
    sql = t.render(class_name=class_name, state_name=state,
                   state_periods=periods)
    return sql


def sql_attribute_array(attribute, periods):
    """Return an SQL array of type <attribute>AttrType[]."""
    t = jinja_env.get_template('attribute_array.sql')
    sql = t.render(attribute_name=attribute, attribute_periods=periods)
    return sql


def sql_relations_array(class_name, relations):
    """Return an SQL array of type <class_name>RelationType[]."""
    t = jinja_env.get_template('relations_array.sql')
    sql = t.render(class_name=class_name, relations=relations)
    return sql


def sql_convert_registration(registration, class_name):
    """Convert input JSON to the SQL arrays we need."""
    registration["attributes"] = convert_attributes(registration["attributes"])
    registration["relations"] = convert_relations(registration["relations"],
                                                  class_name)
    if "variants" in registration:
        registration["variants"] = adapt(
            convert_variants(registration["variants"])
        )
    states = registration["states"]
    sql_states = []
    for sn in get_state_names(class_name):
        qsn = class_name.lower() + sn  # qualified_state_name
        periods = states[qsn] if qsn in states else None
        sql_states.append(
            sql_state_array(sn, periods, class_name)
        )
    registration["states"] = sql_states

    attributes = registration["attributes"]
    sql_attributes = []
    for a in get_attribute_names(class_name):
        periods = attributes[a] if a in attributes else None
        sql_attributes.append(
            sql_attribute_array(a, periods)
        )
    registration["attributes"] = sql_attributes

    relations = registration["relations"]
    sql_relations = sql_relations_array(class_name, relations)
    # print "CLASS", class_name

    registration["relations"] = sql_relations

    return registration


def sql_get_registration(class_name, time_period, life_cycle_code,
                         user_ref, note, registration):
    """
    Return a an SQL registrering object of type
    <class_name>RegistreringType[].
    Expects a Registration object returned from sql_convert_registration.
    """
    sql_template = jinja_env.get_template('registration.sql')
    sql = sql_template.render(
        class_name=class_name,
        time_period=time_period,
        life_cycle_code=life_cycle_code,
        user_ref=user_ref,
        note=note,
        states=registration["states"],
        attributes=registration["attributes"],
        relations=registration["relations"],
        variants=registration.get("variants", None))
    return sql


def sql_convert_restrictions(class_name, restrictions):
    """Convert a list of restrictions to SQL."""
    registrations = map(
        lambda r: restriction_to_registration(class_name, r),
        restrictions
    )
    sql_restrictions = map(
        lambda r: sql_get_registration(
            class_name, None, None, None, None,
            sql_convert_registration(r, class_name)
        ),
        registrations
    )
    return sql_restrictions


def get_restrictions_as_sql(user, class_name, operation):
    """Get restrictions for user and operation, return as array of SQL."""
    if not DO_ENABLE_RESTRICTIONS:
        return None
    restrictions = get_restrictions(user, class_name, operation)
    if restrictions == []:
        raise NotAllowedException("Not allowed!")
    elif restrictions is None:
        return None

    sql_restrictions = sql_convert_restrictions(class_name, restrictions)
    sql_template = jinja_env.get_template('restrictions.sql')
    sql = sql_template.render(restrictions=sql_restrictions)
    return sql


"""
    GENERAL OBJECT RELATED FUNCTIONS
"""


def object_exists(class_name, uuid):
    """Check if an object with this class name and UUID exists already."""
    sql = ("select (%s IN (SELECT DISTINCT " + class_name +
           "_id from " + class_name + "_registrering))")
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql, (uuid,))
    except psycopg2.Error as e:
        if e.pgcode[:2] == 'MO':
            status_code = int(e.pgcode[2:])
            raise DBException(status_code, e.message)
        else:
            raise

    result = cursor.fetchone()[0]

    return result


def get_document_from_content_url(content_url):
    """Return the UUID of the Dokument which has a specific indhold URL.

    Also returns the mimetype of the indhold URL as stored in the
    DokumenDelEgenskaber.
    """
    sql = """select r.dokument_id, de.mimetype from
             actual_state.dokument_del_egenskaber de
join actual_state.dokument_del d on d.id = de.del_id join
actual_state.dokument_variant v on v.id = d.variant_id join
actual_state.dokument_registrering r on r.id = v.dokument_registrering_id
where de.indhold = %s"""
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql, (content_url,))
    except psycopg2.Error as e:
        if e.pgcode[:2] == 'MO':
            status_code = int(e.pgcode[2:])
            raise DBException(status_code, e.message)
        else:
            raise

    result = cursor.fetchone()
    return result


def create_or_import_object(class_name, note, registration,
                            uuid=None):
    """Create a new object by calling the corresponding stored procedure.

    Create a new object by calling actual_state_create_or_import_{class_name}.
    It is necessary to map the parameters to our custom PostgreSQL data types.
    """

    # Data from the BaseRegistration.
    # Do not supply date, that is generated by the DB.
    life_cycle_code = (Livscyklus.OPSTAAET.value if uuid is None
                       else Livscyklus.IMPORTERET.value)
    user_ref = get_authenticated_user()

    registration = sql_convert_registration(registration, class_name)
    sql_registration = sql_get_registration(class_name, None, life_cycle_code,
                                            user_ref, note, registration)

    sql_restrictions = get_restrictions_as_sql(
        get_authenticated_user(),
        class_name,
        Operation.CREATE
    )

    sql_template = jinja_env.get_template('create_object.sql')
    sql = sql_template.render(
        class_name=class_name,
        uuid=uuid,
        life_cycle_code=life_cycle_code,
        user_ref=user_ref,
        note=note,
        registration=sql_registration,
        restrictions=sql_restrictions)

    print sql
    # Call Postgres! Return OK or not accordingly
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql)
    except psycopg2.Error as e:
        noop_msg = ('Aborted updating {} with id [{}] as the given data, '
                    'does not give raise to a new registration.'.format(
                        class_name, uuid
                    ))

        if e.pgcode[:2] == 'MO':
            status_code = int(e.pgcode[2:])
            raise DBException(status_code, e.message)
        elif e.message.startswith(noop_msg):
            status_code = int(e.pgcode[2:])
            raise DBException(status_code, 'fuck no')
        else:
            raise

    output = cursor.fetchone()
    return output[0]


def delete_object(class_name, registration, note, uuid):
    """Delete object by using the stored procedure.

    Deleting is the same as updating with the life cycle code "Slettet".
    """

    user_ref = get_authenticated_user()
    life_cycle_code = Livscyklus.SLETTET.value
    sql_template = jinja_env.get_template('update_object.sql')
    registration = sql_convert_registration(registration, class_name)
    sql_restrictions = get_restrictions_as_sql(
        get_authenticated_user(),
        class_name,
        Operation.DELETE
    )
    sql = sql_template.render(
        class_name=class_name,
        uuid=uuid,
        life_cycle_code=life_cycle_code,
        user_ref=user_ref,
        note=note,
        states=registration["states"],
        attributes=registration["attributes"],
        relations=registration["relations"],
        variants=registration.get("variants", None),
        restrictions=sql_restrictions
    )
    # Call Postgres! Return OK or not accordingly
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql)
    except psycopg2.Error as e:
        not_found_msg = (
            'Unable to update {} with uuid [{}], '
            'being unable to find any previous registrations.\n'
        ).format(class_name.lower(), uuid)

        if e.message == not_found_msg:
            raise NotFoundException(e.message)
        if e.pgcode[:2] == 'MO':
            status_code = int(e.pgcode[2:])
            raise DBException(status_code, e.message)
        else:
            raise

    output = cursor.fetchone()
    return output[0]


def passivate_object(class_name, note, registration, uuid):
    """Passivate object by calling the stored procedure."""

    user_ref = get_authenticated_user()
    life_cycle_code = Livscyklus.PASSIVERET.value
    sql_template = jinja_env.get_template('update_object.sql')
    registration = sql_convert_registration(registration, class_name)
    sql_restrictions = get_restrictions_as_sql(
        get_authenticated_user(),
        class_name,
        Operation.PASSIVATE
    )
    sql = sql_template.render(
        class_name=class_name,
        uuid=uuid,
        life_cycle_code=life_cycle_code,
        user_ref=user_ref,
        note=note,
        states=registration["states"],
        attributes=registration["attributes"],
        relations=registration["relations"],
        variants=registration.get("variants", None),
        restrictions=sql_restrictions
    )
    # Call PostgreSQL
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql)
    except psycopg2.Error as e:
        if e.pgcode[:2] == 'MO':
            status_code = int(e.pgcode[2:])
            raise DBException(status_code, e.message)
        else:
            raise

    output = cursor.fetchone()
    return output[0]


def update_object(class_name, note, registration, uuid=None,
                  life_cycle_code=Livscyklus.RETTET.value):
    """Update object with the partial data supplied."""
    user_ref = get_authenticated_user()

    registration = sql_convert_registration(registration, class_name)

    sql_restrictions = get_restrictions_as_sql(
        get_authenticated_user(),
        class_name,
        Operation.UPDATE
    )

    sql_template = jinja_env.get_template('update_object.sql')
    sql = sql_template.render(
        class_name=class_name,
        uuid=uuid,
        life_cycle_code=life_cycle_code,
        user_ref=user_ref,
        note=note,
        states=registration["states"],
        attributes=registration["attributes"],
        relations=registration["relations"],
        variants=registration.get("variants", None),
        restrictions=sql_restrictions)
    # Call PostgreSQL
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql)
        cursor.fetchone()
    except psycopg2.Error as e:
        noop_msg = ('Aborted updating {} with id [{}] as the given data, '
                    'does not give raise to a new registration.'.format(
                        class_name.lower(), uuid
                    ))

        if e.message.startswith(noop_msg):
            return uuid
        elif e.pgcode[:2] == 'MO':
            status_code = int(e.pgcode[2:])
            raise DBException(status_code, e.message)
        else:
            raise

    return uuid


def list_objects(class_name, uuid, virkning_fra, virkning_til,
                 registreret_fra, registreret_til):
    """List objects with the given uuids, optionally filtering by the given
    virkning and registering periods."""

    assert isinstance(uuid, list) or not uuid

    sql_template = jinja_env.get_template('list_objects.sql')

    sql_restrictions = get_restrictions_as_sql(
        get_authenticated_user(),
        class_name,
        Operation.READ
    )

    sql = sql_template.render(
        class_name=class_name,
        restrictions=sql_restrictions
    )

    registration_period = None
    if registreret_fra is not None or registreret_til is not None:
        registration_period = DateTimeTZRange(registreret_fra, registreret_til)

    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql, {
            'uuid': uuid,
            'registrering_tstzrange': registration_period,
            'virkning_tstzrange': DateTimeTZRange(virkning_fra, virkning_til)
        })
    except psycopg2.Error as e:
        if e.pgcode[:2] == 'MO':
            status_code = int(e.pgcode[2:])
            raise DBException(status_code, e.message)
        else:
            raise

    output = cursor.fetchone()
    if not output:
        # nothing found
        raise NotFoundException("{0} with UUID {1} not found.".format(
            class_name, uuid
        ))
    # import json
    # print json.dumps(output, indent=2)
    return filter_json_output(output)


def filter_json_output(output):
    """Filter the JSON output returned from the DB-layer."""
    return transform_relations(transform_virkning(filter_empty(
        simplify_cleared_wrappers(output))))


def simplify_cleared_wrappers(o):
    """Recursively simplify any values wrapped in a cleared-wrapper.

    {"blah": {"value": true, "cleared": false}} becomes simply {"blah": true}

    The dicts could be contained in lists or tuples or other dicts.
    """
    if isinstance(o, dict):
        if "cleared" in o:
            # Handle clearable wrapper db-types.
            return o.get("value", None)
        else:
            return {k: simplify_cleared_wrappers(v) for k, v in o.iteritems()}
    elif isinstance(o, list):
        return [simplify_cleared_wrappers(v) for v in o]
    elif isinstance(o, tuple):
        return tuple(simplify_cleared_wrappers(v) for v in o)
    else:
        return o


def transform_virkning(o):
    """Recurse through output to transform Virkning time periods."""
    if isinstance(o, dict):
        if "timeperiod" in o:
            # Handle clearable wrapper db-types.
            f, t = o["timeperiod"][1:-1].split(',')
            from_included = o["timeperiod"][0] == '['
            to_included = o["timeperiod"][-1] == ']'

            # Get rid of quotes
            if f[0] == '"':
                f = f[1:-1]
            if t[0] == '"':
                t = t[1:-1]
            items = o.items() + [
                ('from', f), ('to', t), ("from_included", from_included),
                ("to_included", to_included)
            ]
            return {k: v for k, v in items if k != "timeperiod"}
        else:
            return {k: transform_virkning(v) for k, v in o.iteritems()}
    elif isinstance(o, list):
        return [transform_virkning(v) for v in o]
    elif isinstance(o, tuple):
        return tuple(transform_virkning(v) for v in o)
    else:
        return o


def filter_empty(d):
    """Recursively filter out empty dictionary keys."""
    if type(d) is dict:
        return dict(
            (k, filter_empty(v)) for k, v in d.iteritems() if v and
            filter_empty(v)
        )
    elif type(d) is list:
        return [filter_empty(v) for v in d if v and filter_empty(v)]
    elif type(d) is tuple:
        return tuple(filter_empty(v) for v in d if v and filter_empty(v))
    else:
        return d


def transform_relations(o):
    """Recurse through output to transform relation lists to dicts.

    Currently, this only applies to DokumentDel relations, because the cast
    to.JSON for other types of relations is currently done in PostgreSQL cast
    functions.
    """
    if isinstance(o, dict):
        if "relationer" in o and (isinstance(o["relationer"], list) or
                                  isinstance(o["relationer"], tuple)):
            relations = o["relationer"]
            rel_dict = {}
            for rel in relations:
                # Remove the reltype from the dict and add to the output dict
                rel_type = rel.pop("reltype")
                rel_dict.setdefault(rel_type, []).append(rel)
            o["relationer"] = rel_dict
            return o
        else:
            return {k: transform_relations(v) for k, v in o.iteritems()}
    elif isinstance(o, list):
        return [transform_relations(v) for v in o]
    elif isinstance(o, tuple):
        return tuple(transform_relations(v) for v in o)
    else:
        return o


'''
TODO: Remove this function if/when it turns out we don't need it.
def filter_nulls(o):
    """Recursively remove keys with None values from dicts in object.

    The dicts could be contained in lists or tuples or other dicts.
    """
    if isinstance(o, dict):
        if "cleared" in o:
            # Handle clearable wrapper db-types.
            return o.get("value", None)
        else:
            return {k: filter_nulls(v) for k, v in o.iteritems()
                    if v is not None and filter_nulls(v) is not None}
    elif isinstance(o, list):
        return [filter_nulls(v) for v in o]
    elif isinstance(o, tuple):
        return tuple(filter_nulls(v) for v in o)
    else:
        return o
'''


def search_objects(class_name, uuid, registration,
                   virkning_fra=None, virkning_til=None,
                   registreret_fra=None, registreret_til=None,
                   life_cycle_code=None, user_ref=None, note=None,
                   any_attr_value_arr=None, any_rel_uuid_arr=None,
                   first_result=0, max_results=2147483647):
    if not any_attr_value_arr:
        any_attr_value_arr = []
    if not any_rel_uuid_arr:
        any_rel_uuid_arr = []
    if uuid is not None:
        assert isinstance(uuid, basestring)

    time_period = None
    if registreret_fra is not None or registreret_til is not None:
        time_period = DateTimeTZRange(registreret_fra, registreret_til)

    registration = sql_convert_registration(registration, class_name)
    sql_registration = sql_get_registration(class_name, time_period,
                                            life_cycle_code, user_ref, note,
                                            registration)

    sql_template = jinja_env.get_template('search_objects.sql')

    virkning_soeg = None
    if virkning_fra is not None or virkning_til is not None:
        virkning_soeg = DateTimeTZRange(virkning_fra, virkning_til)

    sql_restrictions = get_restrictions_as_sql(
        get_authenticated_user(),
        class_name,
        Operation.READ
    )

    sql = sql_template.render(
        first_result=first_result,
        uuid=uuid,
        class_name=class_name,
        registration=sql_registration,
        any_attr_value_arr=any_attr_value_arr,
        any_rel_uuid_arr=any_rel_uuid_arr,
        max_results=max_results,
        virkning_soeg=virkning_soeg,
        # TODO: Get this into the SQL function signature!
        restrictions=sql_restrictions
    )
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql)
    except psycopg2.Error as e:
        if e.pgcode[:2] == 'MO':
            status_code = int(e.pgcode[2:])
            raise DBException(status_code, e.message)
        else:
            raise

    output = cursor.fetchone()
    return output


def get_life_cycle_code(class_name, uuid):
    n = datetime.now()
    n1 = n + timedelta(seconds=1)
    regs = list_objects(class_name, [uuid], n, n1, n, n1)
    reg = regs[0][0]
    livscykluskode = reg['registreringer'][0]['livscykluskode']

    return livscykluskode
