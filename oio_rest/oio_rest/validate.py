import copy
import jsonschema

import db_structure as db

# A very nice reference explaining the JSON schema syntax can be found
# here: https://spacetelescope.github.io/understanding-json-schema/

# JSON schema types
BOOLEAN = {'type': 'boolean'}
INTEGER = {'type': 'integer'}
STRING = {'type': 'string'}
UUID = {
    'type': 'string',
    'pattern': '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-'
               '[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$'
}


def _generate_schema_array(items, maxItems=None):
    schema_array = {
        'type': 'array',
        'items': items
    }
    if maxItems:
        schema_array['maxItems'] = maxItems
    return schema_array


def _generate_schema_object(properties, required, kwargs=None):
    schema_obj = {
        'type': 'object',
        'properties': properties,
        'required': required,
        'additionalProperties': False
    }
    if kwargs:
        schema_obj.update(kwargs)
    return schema_obj

# Mapping from DATABASE_STRUCTURE types to JSON schema types

TYPE_MAP = {
    'aktoerattr': _generate_schema_object(
        {
            'accepteret': STRING,
            'obligatorisk': STRING,
            'repraesentation_uuid': UUID,
        },
        ['accepteret', 'obligatorisk', 'repraesentation_uuid']
    ),
    'boolean': BOOLEAN,
    'date': STRING,
    'int': INTEGER,
    'interval(0)': STRING,
    'journaldokument': _generate_schema_object(
        {
            'dokumenttitel': STRING,
            'offentlighedundtaget': {
                '$ref': '#/definitions/offentlighedundtaget'}
        },
        ['dokumenttitel', 'offentlighedundtaget']
    ),
    'journalnotat': _generate_schema_object(
        {
            'titel': STRING,
            'notat': STRING,
            'format': STRING,
        },
        ['titel', 'notat', 'format']
    ),
    'offentlighedundtagettype': {
        '$ref': '#/definitions/offentlighedundtaget'},
    'soegeord': _generate_schema_array(_generate_schema_array(STRING), 2),
    'text[]': _generate_schema_array(STRING),
    'timestamptz': STRING,
    'vaerdirelationattr': _generate_schema_object(
        {
            'forventet': BOOLEAN,
            'nominelvaerdi': STRING
        },
        ['forventet', 'nominelvaerdi']
    )
}


def _get_metadata(obj, metadata_type, key):
    """
    Get the metadata for a given attribute
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :param metadata_type: Must be either 'attributter' or 'relationer'
    :param key: The attribute to get the metadata from,
    e.g. 'egenskaber'
    :return: Dictionary containing the metadata for the attribute fields
    """
    metadata = db.REAL_DB_STRUCTURE[obj].get(
        '{}_metadata'.format(metadata_type), [])
    if not metadata:
        return metadata
    return metadata[key]


def _get_mandatory(obj, attribute_name):
    """
    Get a list of mandatory attribute fields for a given attribute.
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :param attribute_name: The attribute to get the fields from,
    e.g. 'egenskaber'
    :return: Sorted list of mandatory attribute keys
    """
    attribute = _get_metadata(obj, 'attributter', attribute_name)
    mandatory = [
        key for key in attribute if attribute[key].get('mandatory', False)
    ]
    mandatory.sort()

    return mandatory


def _handle_attribute_metadata(obj, fields, attribute_name):
    """
    Update the types of the attribute fields.
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :param fields: A dictionary of attribute fields to update.
    :param attribute_name: The name of the attribute fields
    :return: Dictionary of updated attribute fields.
    """
    attribute = _get_metadata(obj, 'attributter', attribute_name)
    fields.update(
        {
            key: TYPE_MAP[attribute[key]['type']]
            for key in attribute if attribute[key].get('type', False)
        }
    )

    return fields


def _generate_attributter(obj):
    """
    Generate the 'attributter' part of the JSON schema.
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :return: Dictionary representing the 'attributter' part of the JSON schema.
    """

    db_attributter = db.REAL_DB_STRUCTURE[obj]['attributter']

    egenskaber_name = '{}egenskaber'.format(obj)
    egenskaber = {
        key: STRING
        for key in db_attributter['egenskaber']
    }
    egenskaber.update({'virkning': {'$ref': '#/definitions/virkning'}})

    egenskaber = _handle_attribute_metadata(obj, egenskaber, 'egenskaber')

    return _generate_schema_object(
        {
            egenskaber_name: _generate_schema_array(
                _generate_schema_object(
                    egenskaber,
                    _get_mandatory(obj, 'egenskaber') + ['virkning'])
            )
        },
        [egenskaber_name]
    )


def _generate_tilstande(obj):
    """
    Generate the 'tilstande' part of the JSON schema.
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :return: Dictionary representing the 'tilstande' part of the JSON schema.
    """

    tilstande = dict(db.REAL_DB_STRUCTURE[obj]['tilstande'])

    properties = {}
    required = []
    for key in tilstande.keys():
        tilstand_name = obj + key

        properties[tilstand_name] = _generate_schema_array(
            _generate_schema_object(
                {
                    key: {
                        'type': 'string',
                        'enum': tilstande[key]
                    },
                    'virkning': {'$ref': '#/definitions/virkning'},
                },
                [key, 'virkning']
            )
        )

        required.append(tilstand_name)

    return _generate_schema_object(properties, required)


def _handle_relation_metadata_all(obj, relation):
    """
    Update relations an their metadata (e.g. types) for all relations of the
    given LoRa object.
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :param relation: The base relation to update.
    :return: Dictionary representing the updated relation.
    """
    metadata_all = _get_metadata(obj, 'relationer', 'all')
    for key in metadata_all:
        if metadata_all[key].has_key('type'):
            relation['items']['properties'][key] = TYPE_MAP[
                metadata_all[key]['type']]
    return relation


def _handle_relation_metadata_specific(obj, relation_schema):
    """
    Update relations an their metadata (e.g. types) for specific relations
    of the given LoRa object.
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :param relation_schema: Dictionary representing the 'relationer' part of
    the JSON schema.
    :return: Dictionary representing the updated 'relationer' part of
    the JSON schema.
    """
    metadata_specific = db.REAL_DB_STRUCTURE[obj].get('relationer_metadata',
                                                      [])
    for relation in [key for key in metadata_specific if not key == 'all']:
        properties = relation_schema[relation]['items']['properties']
        metadata = metadata_specific[relation]
        for key in metadata:
            if metadata[key].has_key('type'):
                properties[key] = TYPE_MAP[metadata[key]['type']]
            if metadata[key].has_key('enum'):
                # Enum implies type = text
                properties[key] = {
                    'type': 'string',
                    'enum': metadata[key]['enum']
                }
            if metadata[key].get('mandatory', False):
                relation_schema[relation]['items']['required'].append(key)

    if obj == 'tilstand':

        # Handle special case for 'tilstand' where UUID not allowed

        del relation_schema['tilstandsvaerdi']['items']['properties']['uuid']
        relation_schema['tilstandsvaerdi']['items']['required'].remove(
            'uuid')

    return relation_schema


def _generate_relationer(obj):
    """
    Generate the 'relationer' part of the JSON schema.
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :return: Dictionary representing the 'relationer' part of the JSON schema.
    """
    relationer_nul_til_en = db.REAL_DB_STRUCTURE[obj]['relationer_nul_til_en']
    relationer_nul_til_mange = db.REAL_DB_STRUCTURE[obj][
        'relationer_nul_til_mange']

    relation_nul_til_mange = _generate_schema_array(
        _generate_schema_object(
            {
                'uuid': UUID,
                'virkning': {'$ref': '#/definitions/virkning'},
                'objekttype': STRING
            },
            ['uuid', 'virkning']
        )
    )

    relation_nul_til_mange = _handle_relation_metadata_all(
        obj, relation_nul_til_mange)

    relation_schema = {
        relation: copy.deepcopy(relation_nul_til_mange)
        for relation in relationer_nul_til_mange
    }

    relation_nul_til_en = copy.deepcopy(relation_nul_til_mange)
    relation_nul_til_en['maxItems'] = 1

    for relation in relationer_nul_til_en:
        relation_schema[relation] = relation_nul_til_en

    relation_schema = _handle_relation_metadata_specific(obj, relation_schema)

    return {
        'type': 'object',
        'properties': relation_schema,
        'additionalProperties': False
    }


def _generate_varianter():
    """
    Function to generate the special 'varianter' section of the JSON schema
    used for the the 'Dokument' LoRa object type.
    """

    return _generate_schema_array(_generate_schema_object(
        {
            'egenskaber': _generate_schema_array(_generate_schema_object(
                {
                    'varianttekst': STRING,
                    'arkivering': BOOLEAN,
                    'delvisscannet': BOOLEAN,
                    'offentliggoerelse': BOOLEAN,
                    'produktion': BOOLEAN,
                    'virkning': {'$ref': '#/definitions/virkning'}
                },
                ['varianttekst', 'virkning']
            ))
        },
        ['egenskaber']
    ))


def get_lora_object_type(req):
    """
    Get the LoRa object type from the request.
    :param req: The JSON body from the LoRa request.
    :raise jsonschema.exceptions.ValidationError: If the LoRa object type
    cannot be determined.
    :return: The LoRa object type, i.e. 'organisation', 'bruger',...
    """

    jsonschema.validate(
        req,
        {
            'type': 'object',
            'properties': {
                'attributter': {
                    'type': 'object',
                },

            },
            'required': ['attributter']
        }
    )

    # TODO: this can probably be made smarter using the "oneOf" JSON schema
    # keyword in the schema above, but there were problems getting this to work

    if not len(req['attributter']) == 1:
        raise jsonschema.exceptions.ValidationError('ups')
    if not req['attributter'].keys()[0] in [key + 'egenskaber' for key in
                                            db.REAL_DB_STRUCTURE.keys()]:
        raise jsonschema.exceptions.ValidationError('ups2')

    return req['attributter'].keys()[0].split('egenskaber')[0]


def generate_json_schema(obj):
    """
    Generate the JSON schema corresponding to LoRa object type.
    :param obj: The LoRa object type, i.e. 'bruger', 'organisation',...
    :return: Dictionary representing the JSON schema.
    """

    schema = _generate_schema_object(
        {
            'attributter': _generate_attributter(obj),
            'tilstande': _generate_tilstande(obj),
            'relationer': _generate_relationer(obj),
            'note': STRING,
        },
        ['attributter', 'tilstande']
    )

    schema['$schema'] = 'http://json-schema.org/schema#'
    schema['id'] = 'http://github.com/magenta-aps/mox'

    schema['definitions'] = {
        'virkning': _generate_schema_object(
            {
                'from': STRING,
                'to': STRING,
                'from_included': BOOLEAN,
                'to_included': BOOLEAN,
                'aktoerref': UUID,
                'aktoertypekode': STRING,
                'notetekst': STRING,
            },
            ['from', 'to']
        ),
        'offentlighedundtaget': _generate_schema_object(
            {
                'alternativtitel': STRING,
                'hjemmel': STRING
            },
            ['alternativtitel', 'hjemmel']
        )
    }

    return schema


SCHEMA = {
    obj: copy.deepcopy(generate_json_schema(obj))
    for obj in db.REAL_DB_STRUCTURE.keys()
}


def validate(input_json):
    """
    Validate request JSON according to JSON schema.
    :param input_json: The request JSON
    :raise ValidationError: If the request JSON is not valid according to the
    JSON schema.
    """
    obj_type = get_lora_object_type(input_json)
    jsonschema.validate(input_json, SCHEMA[obj_type])
