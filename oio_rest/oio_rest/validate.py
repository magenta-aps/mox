import copy
import jsonschema

import db_structure as db

# A very nice reference explaining the JSON schema syntax can be found
# here: https://spacetelescope.github.io/understanding-json-schema/

# LoRa object types
AKTIVITET = 'aktivitet'
DOKUMENT = 'dokument'
INDSATS = 'indsats'
ITSYSTEM = 'itsystem'
KLASSE = 'klasse'
SAG = 'sag'
TILSTAND = 'tilstand'

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


def _handle_special_egenskaber(obj, egenskaber):
    if obj == KLASSE:
        egenskaber['soegeord'] = _generate_schema_array(
            _generate_schema_array(STRING), 2)
    if obj == ITSYSTEM:
        egenskaber['konfigurationreference'] = _generate_schema_array(STRING)
    if obj == SAG:
        egenskaber['afleveret'] = BOOLEAN
        egenskaber['principiel'] = BOOLEAN
        egenskaber['offentlighedundtaget'] = {
            '$ref': '#/definitions/offentlighedundtaget'}
    if obj == DOKUMENT:
        egenskaber['major'] = INTEGER
        egenskaber['minor'] = INTEGER
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
        key: STRING
        for key in db_attributter['egenskaber']
    }
    egenskaber.update({'virkning': {'$ref': '#/definitions/virkning'}})

    egenskaber = _handle_special_egenskaber(obj, egenskaber)

    return _generate_schema_object(
        {
            egenskaber_name: _generate_schema_array(
                _generate_schema_object(egenskaber, db_attributter[
                    'required_egenskaber'] + ['virkning'])
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

    tilstande = db.REAL_DB_STRUCTURE[obj]['tilstande']

    properties = {}
    required = []
    for key in tilstande.keys():
        tilstand_name = '{}{}'.format(obj, key)

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


def _handle_special_relations_all(obj, relation):
    if obj in [AKTIVITET, INDSATS, SAG, TILSTAND]:
        relation['items']['properties']['indeks'] = INTEGER
    if obj == AKTIVITET:
        relation['items']['properties']['aktoerattr'] = _generate_schema_object(
            {
                'accepteret': STRING,
                'obligatorisk': STRING,
                'repraesentation_uuid': UUID,
            },
            ['accepteret', 'obligatorisk', 'repraesentation_uuid']
        )
    return relation


def _handle_special_relations_specific(obj, relation_schema):
    if obj == TILSTAND:
        properties = relation_schema['tilstandsvaerdi']['items']['properties']
        properties['tilstandsvaerdiattr'] = _generate_schema_object(
            {
                'forventet': BOOLEAN,
                'nominelvaerdi': STRING
            },
            ['forventet', 'nominelvaerdi']
        )
        properties.pop('uuid')
        relation_schema['tilstandsvaerdi']['items']['required'].remove('uuid')
    if obj == SAG:
        properties = relation_schema['journalpost']['items']['properties']
        properties['journalpostkode'] = {
            'type': 'string',
            'enum': ['journalnotat', 'vedlagtdokument']
        }
        properties['journalnotat'] = _generate_schema_object(
            {
                'titel': STRING,
                'notat': STRING,
                'format': STRING,
            },
            ['titel', 'notat', 'format']
        )
        properties['journaldokument'] = _generate_schema_object(
            {
                'dokumenttitel': STRING,
                'offentlighedundtaget': {
                    '$ref': '#/definitions/offentlighedundtaget'}
            },
            ['dokumenttitel', 'offentlighedundtaget']
        )
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
    schema['definitions'] = {
        'virkning': _generate_schema_object(
            {
                'from': STRING,
                'to': STRING,
                'from_included': BOOLEAN,
                'to_included': BOOLEAN,
                'aktoerref': STRING,
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
