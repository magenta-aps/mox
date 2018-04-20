import copy
import json

import jsonschema

import db_structure as db

# A very nice reference explaining the JSON schema syntax can be found
# here: https://spacetelescope.github.io/understanding-json-schema/


UUID_PATTERN = '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-' \
               '[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$'

# LoRa object types

AKTIVITET = 'aktivitet'
DOKUMENT = 'dokument'
INDSATS = 'indsats'
ITSYSTEM = 'itsystem'
KLASSE = 'klasse'
SAG = 'sag'
TILSTAND = 'tilstand'

# Primitive JSON schema types
BOOLEAN = {'type': 'boolean'}
INTEGER = {'type': 'integer'}
STRING = {'type': 'string'}


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


def _handle_special_egenskaber(obj, egenskaber):
    if obj == KLASSE:
        egenskaber['soegeord'] = {
            'type': 'array',
            'items': {
                'type': 'array',
                'items': {'type': 'string'}
            },
            'maxItems': 2
        }
    if obj == ITSYSTEM:
        egenskaber['konfigurationreference'] = {
            'type': 'array',
            'items': {'type': 'string'}
        }
    if obj == SAG:
        egenskaber['afleveret'] = {'type': 'boolean'}
        egenskaber['principiel'] = {'type': 'boolean'}
        egenskaber['offentlighedundtaget'] = {
            '$ref': '#/definitions/offentlighedundtaget'}

    return egenskaber


def _generate_attributter(obj):
    """
    Generate the 'attributter' part of the JSON schema.
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :return: Dictionary representing the 'attributter' part of the JSON schema.
    """

    db_attributter = db.REAL_DB_STRUCTURE[obj]['attributter']

    egenskaber_name = '{}egenskaber'.format(obj)
    egenskaber = {
        key: {'type': 'string'}
        for key in db_attributter['egenskaber']
    }
    egenskaber.update({'virkning': {'$ref': '#/definitions/virkning'}})

    egenskaber = _handle_special_egenskaber(obj, egenskaber)

    return _generate_schema_object(
        {
            egenskaber_name: {
                'type': 'array',
                'items': _generate_schema_object(egenskaber, db_attributter[
                    'required_egenskaber'] + ['virkning'])
            }
        },
        [egenskaber_name]
    )


def _generate_tilstande(obj):
    """
    Generate the 'tilstande' part of the JSON schema.
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :return: Dictionary representing the 'tilstande' part of the JSON schema.
    """

    tilstande = db.REAL_DB_STRUCTURE[obj]['tilstande']

    properties = {}
    required = []
    for key in tilstande.keys():
        tilstand_name = '{}{}'.format(obj, key)

        properties[tilstand_name] = {
            'type': 'array',
            'items': _generate_schema_object(
                {
                    key: {
                        'type': 'string',
                        'enum': tilstande[key]
                    },
                    'virkning': {'$ref': '#/definitions/virkning'},
                },
                [key, 'virkning']
            )
        }

        required.append(tilstand_name)

    return _generate_schema_object(properties, required)


def _handle_special_relations_all(obj, relation):
    if obj in [AKTIVITET, INDSATS, SAG, TILSTAND]:
        relation['items']['properties']['indeks'] = INTEGER
    if obj == AKTIVITET:
        relation['items']['properties']['aktoerattr'] = _generate_schema_object(
            {
                'accepteret': {'type': 'string'},
                'obligatorisk': {'type': 'string'},
                'repraesentation_uuid': {
                    'type': 'string',
                    'pattern': UUID_PATTERN
                },
            },
            ['accepteret', 'obligatorisk', 'repraesentation_uuid']
        )
    return relation


def _handle_special_relations_specific(obj, relation_schema):
    if obj == TILSTAND:
        # Refactor... make properties variable
        relation_schema['tilstandsvaerdi']['items']['properties'][
            'tilstandsvaerdiattr'] = {
            'type': 'object',
            'properties': {
                'forventet': {'type': "boolean"},
                'nominelvaerdi': {'type': 'string'}
            },
            'required': ['forventet', 'nominelvaerdi'],
            'additionalProperties': False
        }
        relation_schema['tilstandsvaerdi']['items']['properties'].pop('uuid')
        relation_schema['tilstandsvaerdi']['items']['required'].remove('uuid')
    if obj == SAG:
        properties = relation_schema['journalpost']['items']['properties']
        properties['journalpostkode'] = {
            'type': 'string',
            'enum': ['journalnotat', 'vedlagtdokument']
        }
        properties['journalnotat'] = {
            'type': 'object',
            'properties': {
                'titel': {'type': 'string'},
                'notat': {'type': 'string'},
                'format': {'type': 'string'},
            },
            'required': ['titel', 'notat',
                         'format'],
            'additionalProperties': False
        }
        properties['journaldokument'] = {
            'type': 'object',
            'properties': {
                'dokumenttitel': {'type': 'string'},
                'offentlighedundtaget': {
                    '$ref': '#/definitions/offentlighedundtaget'}
            }
        }
        relation_schema['journalpost']['items']['required'].append(
            'journalpostkode')

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

    relation_nul_til_mange = {
        'type': 'array',
        'items': {
            'type': 'object',
            'properties': {
                'uuid': {
                    'type': 'string',
                    'pattern': UUID_PATTERN
                },
                'virkning': {'$ref': '#/definitions/virkning'},
                'objekttype': {'type': 'string'}
            },
            'required': ['uuid', 'virkning'],
            'additionalProperties': False
        }
    }

    relation_nul_til_mange = _handle_special_relations_all(
        obj, relation_nul_til_mange)

    relation_schema = {
        relation: copy.deepcopy(relation_nul_til_mange)
        for relation in relationer_nul_til_mange
    }

    relation_nul_til_en = copy.deepcopy(relation_nul_til_mange)
    relation_nul_til_en['maxItems'] = 1

    for relation in relationer_nul_til_en:
        relation_schema[relation] = relation_nul_til_en

    relation_schema = _handle_special_relations_specific(obj, relation_schema)

    return {
        'type': 'object',
        'properties': relation_schema,
        'additionalProperties': False
    }


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

    return {
        '$schema': "http://json-schema.org/schema#",

        'definitions': {
            'virkning': {
                'type': 'object',
                'properties': {
                    'from': {'type': 'string'},
                    'to': {'type': 'string'},
                    'from_included': {'type': 'boolean'},
                    'to_included': {'type': 'boolean'},
                    'aktoerref': {'type': 'string'},
                    'aktoertypekode': {'type': 'string'},
                    'notetekst': {'type': 'string'},
                },
                'required': ['from', 'to'],
                'additionalProperties': False
            },
            'offentlighedundtaget': {
                'type': 'object',
                'properties': {
                    'alternativtitel': {'type': 'string'},
                    'hjemmel': {'type': 'string'}
                },
                'required': ['alternativtitel', 'hjemmel'],
                'additionalProperties': False
            }
        },

        'type': 'object',
        'properties': {
            'attributter': _generate_attributter(obj),
            'tilstande': _generate_tilstande(obj),
            'relationer': _generate_relationer(obj),
            'note': {'type': 'string'},
        },
        'required': ['attributter', 'tilstande'],
    }


SCHEMA = {
    obj: copy.deepcopy(generate_json_schema(obj))
    for obj in db.REAL_DB_STRUCTURE.keys()
}

# Will be cleaned up later...

# if __name__ == '__main__':
#     print(json.dumps(generate_json_schema({'attributter': {
#         'tilstandegenskaber': []
#     }}), indent=2))
