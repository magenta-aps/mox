from enum import Enum

import os
import psycopg2
from psycopg2.extras import DateTimeTZRange
from psycopg2.extensions import adapt as psyco_adapt

from jinja2 import Template
from jinja2 import Environment, FileSystemLoader

from settings import DATABASE, DB_USER
from db_helpers import get_attribute_fields, get_attribute_names
from db_helpers import get_field_type, get_state_names, Soegeord

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
    connection = psycopg2.connect("dbname={0} user={1}".format(DATABASE,
                                                               DB_USER))
    connection.autocommit = True
    return connection

adapt_connection = get_connection()


def get_authenticated_user():
    """Return hardcoded UUID until we get real authentication in place."""
    # TODO: return request.saml_user_id
    return "615957e8-4aa1-4319-a787-f1f7ad6b5e2c"


def convert(attribute_name, attribute_field_name, attribute_field_value):
    # For simple types that can be adapted by standard psycopg2 adapters, just
    # pass on. For complex types like "Soegeord" with specialized adapters,
    # convert to the class for which the adapter is registered.
    if get_field_type(attribute_name, attribute_field_name) == "soegeord":
        return [Soegeord(*ord) for ord in attribute_field_value]
    else:
        return attribute_field_value


def convert_attributes(attributes):
    "Convert attributes from dictionary to list in correct order."
    for attr_name in attributes:
        current_attr_periods = attributes[attr_name]
        converted_attr_periods = []
        for attr_period in current_attr_periods:
            field_names = get_attribute_fields(attr_name)
            attr_value_list = [
                convert(
                    attr_name, f, attr_period[f]
                ) if f in attr_period else None
                for f in field_names
                ]
            converted_attr_periods.append(attr_value_list)
        attributes[attr_name] = converted_attr_periods
    print attributes
    return attributes


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
    print periods
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


def sql_convert_registration(states, attributes, relations, class_name):
    """Convert input JSON to the SQL arrays we need."""
    sql_states = []
    for s in get_state_names(class_name):
        periods = states[s] if s in states else []
        sql_states.append(
            sql_state_array(s, periods, class_name)
        )

    sql_attributes = []
    for a in get_attribute_names(class_name):
        periods = attributes[a] if a in attributes else []
        sql_attributes.append(
            sql_attribute_array(a, periods)
        )

    sql_relations = sql_relations_array(class_name, relations)

    return (sql_states, sql_attributes, sql_relations)


def sql_get_registration(class_name, time_period, life_cycle_code,
                         user_ref, note, registration_tuple):
    """
    Return a an SQL registrering object of type
    <class_name>RegistreringType[].
    Expects a tuple returned from sql_convert_registration.
    """
    sql_template = jinja_env.get_template('registration.sql')
    sql = sql_template.render(
        class_name=class_name,
        time_period=time_period,
        life_cycle_code=life_cycle_code,
        user_ref=user_ref,
        note=note,
        states=registration_tuple[0],
        attributes=registration_tuple[1],
        relations=registration_tuple[2])
    return sql

"""
    GENRAL OBJECT RELATED FUNCTIONS
"""


def object_exists(class_name, uuid):
    """Check if an object with this class name and UUID exists already."""
    sql = ("select (%s IN (SELECT DISTINCT " + class_name +
           "_id from " + class_name + "_registrering))")
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(sql, (uuid,))
    result = cursor.fetchone()[0]

    return result


def create_or_import_object(class_name, note, attributes, states, relations,
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

    attributes = convert_attributes(attributes)
    registration = sql_convert_registration(states, attributes, relations,
                                            class_name)
    sql_registration = sql_get_registration(class_name, None, life_cycle_code,
                                            user_ref, note, registration)

    sql_template = jinja_env.get_template('create_object.sql')
    sql = sql_template.render(
        class_name=class_name,
        uuid=uuid,
        life_cycle_code=life_cycle_code,
        user_ref=user_ref,
        note=note,
        registration=sql_registration)
    # Call Postgres! Return OK or not accordingly
    conn = get_connection()
    cursor = conn.cursor()
    print sql
    cursor.execute(sql)
    output = cursor.fetchone()
    print output
    return output[0]


def delete_object(class_name, note, uuid):
    """Delete object by using the stored procedure.

    Deleting is the same as updating with the life cycle code "Slettet".
    """

    user_ref = get_authenticated_user()
    life_cycle_code = Livscyklus.SLETTET.value
    sql_template = jinja_env.get_template('delete_object.sql')
    (
        sql_states, sql_attributes, sql_relations
    ) = sql_convert_registration([], [], {}, class_name)
    sql = sql_template.render(
        class_name=class_name,
        uuid=uuid,
        life_cycle_code=life_cycle_code,
        user_ref=user_ref,
        note=note,
        states=sql_states,
        attributes=sql_attributes,
        relations=sql_relations
    )
    print sql
    # Call Postgres! Return OK or not accordingly
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(sql)
    output = cursor.fetchone()
    print output
    return output[0]


def passivate_object(class_name, note, uuid):
    """Passivate object by calling the stored procedure."""

    user_ref = get_authenticated_user()
    life_cycle_code = Livscyklus.PASSIVERET.value
    sql_template = jinja_env.get_template('passivate_object.sql')
    sql = sql_template.render(
        class_name=class_name,
        uuid=uuid,
        life_cycle_code=life_cycle_code,
        user_ref=user_ref,
        note=note
    )
    # Call PostgreSQL
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(sql)
    output = cursor.fetchone()
    print output
    return output[0]


def update_object(class_name, note, attributes, states, relations, uuid=None):
    """Update object with the partial data supplied."""
    life_cycle_code = Livscyklus.RETTET.value
    user_ref = get_authenticated_user()

    attributes = convert_attributes(attributes)
    (
        sql_states, sql_attributes, sql_relations
    ) = sql_convert_registration(states, attributes, relations, class_name)

    sql_template = jinja_env.get_template('update_object.sql')
    sql = sql_template.render(
        class_name=class_name,
        uuid=uuid,
        life_cycle_code=life_cycle_code,
        user_ref=user_ref,
        note=note,
        states=sql_states,
        attributes=sql_attributes,
        relations=sql_relations)
    # Call PostgreSQL
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql)
        output = cursor.fetchone()
        print output
    except psycopg2.DataError:
        # Thrown when no changes
        pass
    return uuid


def list_objects(class_name, uuid, virkning_fra, virkning_til,
                 registreret_fra, registreret_til):
    """List objects with the given uuids, optionally filtering by the given
    virkning and registering periods."""

    assert isinstance(uuid, list)

    sql_template = jinja_env.get_template('list_objects.sql')
    sql = sql_template.render(
        class_name=class_name
    )

    registration_period = None
    if registreret_fra is not None or registreret_til is not None:
        registration_period = DateTimeTZRange(registreret_fra, registreret_til)

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(sql, {
        'uuid': uuid,
        'registrering_tstzrange': registration_period,
        'virkning_tstzrange': DateTimeTZRange(virkning_fra, virkning_til)
    })
    output = cursor.fetchone()
    return filter_nulls(output)

def filter_nulls(o):
    """Recursively remove keys with None values from dicts in object.

    The dicts could be contained in lists or tuples or other dicts.
    """
    if isinstance(o, dict):
        return {k: filter_nulls(v) for k, v in o.iteritems() if v is not None}
    elif isinstance(o, list):
        return [filter_nulls(v) for v in o]
    elif isinstance(o, tuple):
        return tuple(filter_nulls(v) for v in o)
    else:
        return o

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

    (attributes, states, relations) = (registration.get('attributter', None),
                                       registration.get('tilstande', None),
                                       registration.get('relationer', None))

    attributes = convert_attributes(attributes)

    time_period = None
    if registreret_fra is not None or registreret_til is not None:
        time_period = DateTimeTZRange(registreret_fra, registreret_til)

    sql_registration = sql_get_registration(
        class_name,
        time_period,
        life_cycle_code,
        user_ref, note,
        sql_convert_registration(
            states, attributes, relations,
            class_name
        )
    )

    sql_template = jinja_env.get_template('search_objects.sql')

    virkning_soeg = None
    if virkning_fra is not None or virkning_til is not None:
        virkning_soeg = DateTimeTZRange(virkning_fra, virkning_til)

    sql = sql_template.render(
        first_result=first_result,
        uuid=uuid,
        class_name=class_name,
        registration=sql_registration,
        any_attr_value_arr=any_attr_value_arr,
        any_rel_uuid_arr=any_rel_uuid_arr,
        max_results=max_results,
        virkning_soeg=virkning_soeg
    )

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(sql)
    output = cursor.fetchone()
    return output
