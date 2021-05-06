# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


import copy
import jsonschema

from oio_rest.db import db_structure

# A very nice reference explaining the JSON schema syntax can be found
# here: https://spacetelescope.github.io/understanding-json-schema/

# JSON schema types
BOOLEAN = {"type": "boolean"}
INTEGER = {"type": "integer"}
STRING = {"type": "string"}


def _generate_schema_array(items, maxItems=None):
    schema_array = {"type": "array", "items": items}
    if maxItems:
        schema_array["maxItems"] = maxItems
    return schema_array


def _generate_schema_object(properties, required, kwargs=None):
    schema_obj = {
        "type": "object",
        "properties": properties,
        "additionalProperties": False,
    }

    # passing an empty array causes the schema to fail validation...
    if required:
        schema_obj["required"] = required

    if kwargs:
        schema_obj.update(kwargs)
    return schema_obj


# Mapping from DATABASE_STRUCTURE types to JSON schema types


TYPE_MAP = {
    "aktoerattr": _generate_schema_object(
        {
            "accepteret": STRING,
            "obligatorisk": STRING,
            "repraesentation_uuid": {"$ref": "#/definitions/uuid"},
        },
        ["accepteret", "obligatorisk", "repraesentation_uuid"],
    ),
    "boolean": BOOLEAN,
    "date": STRING,
    "int": INTEGER,
    "interval(0)": STRING,
    "journaldokument": _generate_schema_object(
        {
            "dokumenttitel": STRING,
            "offentlighedundtaget": {"$ref": "#/definitions/offentlighedundtaget"},
        },
        ["dokumenttitel", "offentlighedundtaget"],
    ),
    "journalnotat": _generate_schema_object(
        {
            "titel": STRING,
            "notat": STRING,
            "format": STRING,
        },
        ["titel", "notat", "format"],
    ),
    "offentlighedundtagettype": {"$ref": "#/definitions/offentlighedundtaget"},
    "soegeord": _generate_schema_array(_generate_schema_array(STRING), 2),
    "text[]": _generate_schema_array(STRING),
    "timestamptz": STRING,
    "vaerdirelationattr": _generate_schema_object(
        {"forventet": BOOLEAN, "nominelvaerdi": STRING}, ["forventet", "nominelvaerdi"]
    ),
}


def _get_metadata(obj, metadata_type, key):
    """
    Get the metadata for a given attribute
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :param metadata_type: Must be either 'attributter' or 'relationer'
    :param key: The attribute to get the metadata from, e.g. 'egenskaber'
    :return: Dictionary containing the metadata for the attribute fields
    """
    metadata = db_structure.REAL_DB_STRUCTURE[obj].get(
        "{}_metadata".format(metadata_type), []
    )
    if not metadata or key not in metadata:
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
    attribute = _get_metadata(obj, "attributter", attribute_name)

    mandatory = sorted(
        key for key in attribute if attribute[key].get("mandatory", False)
    )

    return mandatory


def _handle_attribute_metadata(obj, fields, attribute_name):
    """
    Update the types of the attribute fields.
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :param fields: A dictionary of attribute fields to update.
    :param attribute_name: The name of the attribute fields
    :return: Dictionary of updated attribute fields.
    """
    attribute = _get_metadata(obj, "attributter", attribute_name)
    fields.update(
        {
            key: TYPE_MAP[attribute[key]["type"]]
            for key in attribute
            if attribute[key].get("type", False)
        }
    )

    return fields


def _generate_attributter(obj, do_create):
    """
    Generate the 'attributter' part of the JSON schema.
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :param do_create: Whether we are creating a new object or not
    :return: Dictionary representing the 'attributter' part of the JSON schema.
    """

    db_attributter = db_structure.REAL_DB_STRUCTURE[obj]["attributter"]

    attrs = {}
    required = []

    for attrname, attrval in db_attributter.items():
        full_name = "{}{}".format(obj, attrname)
        schema = {key: STRING for key in attrval}
        schema.update({"virkning": {"$ref": "#/definitions/virkning"}})

        schema = _handle_attribute_metadata(obj, schema, attrname)

        mandatory = _get_mandatory(obj, attrname)
        attrs[full_name] = _generate_schema_array(
            _generate_schema_object(
                schema, (mandatory if do_create else []) + ["virkning"]
            ),
        )

        if mandatory and do_create:
            required.append(full_name)

    return _generate_schema_object(attrs, required)


def _generate_tilstande(obj, do_create):
    """
    Generate the 'tilstande' part of the JSON schema.
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :param do_create: Whether we are creating a new object or not
    :return: Dictionary representing the 'tilstande' part of the JSON schema.
    """

    tilstande = dict(db_structure.REAL_DB_STRUCTURE[obj]["tilstande"])

    properties = {}
    required = []

    for key in sorted(tilstande):
        tilstand_name = obj + key

        properties[tilstand_name] = _generate_schema_array(
            _generate_schema_object(
                {
                    key: {"type": "string", "enum": tilstande[key]},
                    "virkning": {"$ref": "#/definitions/virkning"},
                },
                [key, "virkning"],
            )
        )
        if do_create:
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
    metadata_all = _get_metadata(obj, "relationer", "*")
    for key in metadata_all:
        if "type" in metadata_all[key]:
            relation["items"]["oneOf"][0]["properties"][key] = TYPE_MAP[
                metadata_all[key]["type"]
            ]
            relation["items"]["oneOf"][1]["properties"][key] = TYPE_MAP[
                metadata_all[key]["type"]
            ]
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
    metadata_specific = db_structure.REAL_DB_STRUCTURE[obj].get(
        "relationer_metadata", []
    )

    for relation in [key for key in metadata_specific if not key == "*"]:
        for i in range(2):
            properties = relation_schema[relation]["items"]["oneOf"][i]["properties"]
            metadata = metadata_specific[relation]
            for key in metadata:
                if "type" in metadata[key]:
                    properties[key] = TYPE_MAP[metadata[key]["type"]]
                if "enum" in metadata[key]:
                    # Enum implies type = text
                    properties[key] = {"type": "string", "enum": metadata[key]["enum"]}
                if metadata[key].get("mandatory", False):
                    relation_schema[relation]["items"]["oneOf"][i]["required"].append(
                        key
                    )

    if obj == "tilstand":
        # Handle special case for 'tilstand' where UUID not allowed

        item = relation_schema["tilstandsvaerdi"]["items"]["oneOf"][0]
        del item["properties"]["uuid"]
        item["required"].remove("uuid")
        relation_schema["tilstandsvaerdi"]["items"] = item

    return relation_schema


def _generate_relationer(obj, do_create):
    """
    Generate the 'relationer' part of the JSON schema.
    :param obj: The type of LoRa object, i.e. 'bruger', 'organisation' etc.
    :param do_create: Whether we are creating a new object or not
    :return: Dictionary representing the 'relationer' part of the JSON schema.
    """
    relationer_nul_til_en = db_structure.REAL_DB_STRUCTURE[obj]["relationer_nul_til_en"]
    relationer_nul_til_mange = db_structure.REAL_DB_STRUCTURE[obj][
        "relationer_nul_til_mange"
    ]

    relation_nul_til_mange = _generate_schema_array(
        {
            "oneOf": [
                _generate_schema_object(
                    {
                        "uuid": {"$ref": "#/definitions/uuid"},
                        "virkning": {"$ref": "#/definitions/virkning"},
                        "objekttype": STRING,
                    },
                    ["uuid", "virkning"],
                ),
                _generate_schema_object(
                    {
                        "urn": {"$ref": "#/definitions/urn"},
                        "virkning": {"$ref": "#/definitions/virkning"},
                        "objekttype": STRING,
                    },
                    ["urn", "virkning"],
                ),
                _generate_schema_object(
                    {
                        "urn": {"$ref": "#/definitions/empty_string"},
                        "uuid": {"$ref": "#/definitions/empty_string"},
                        "virkning": {"$ref": "#/definitions/virkning"},
                    },
                    ["urn", "uuid", "virkning"],
                ),
            ]
        }
    )

    relation_nul_til_mange = _handle_relation_metadata_all(obj, relation_nul_til_mange)

    relation_schema = {
        relation: copy.deepcopy(relation_nul_til_mange)
        for relation in relationer_nul_til_mange
    }

    relation_nul_til_en = copy.deepcopy(relation_nul_til_mange)
    relation_nul_til_en["items"]["oneOf"][0]["properties"].pop("indeks", None)
    relation_nul_til_en["items"]["oneOf"][1]["properties"].pop("indeks", None)

    for relation in relationer_nul_til_en:
        relation_schema[relation] = relation_nul_til_en

    relation_schema = _handle_relation_metadata_specific(obj, relation_schema)

    return {
        "type": "object",
        "properties": relation_schema,
        "additionalProperties": False,
    }


def _generate_varianter():
    """
    Function to generate the special 'varianter' section of the JSON schema
    used for the the 'Dokument' LoRa object type.
    """

    return _generate_schema_array(
        _generate_schema_object(
            {
                "egenskaber": _generate_schema_array(
                    _generate_schema_object(
                        {
                            "varianttekst": STRING,
                            "arkivering": BOOLEAN,
                            "delvisscannet": BOOLEAN,
                            "offentliggoerelse": BOOLEAN,
                            "produktion": BOOLEAN,
                            "virkning": {"$ref": "#/definitions/virkning"},
                        },
                        ["varianttekst", "virkning"],
                    )
                )
            },
            ["egenskaber"],
        )
    )


def generate_json_schema(obj, do_create):
    """
    Generate the JSON schema corresponding to LoRa object type.
    :param obj: The LoRa object type, i.e. 'bruger', 'organisation',...
    :param do_create: Whether we are creating a new object or not
    :return: Dictionary representing the JSON schema.
    """

    if obj == "dokument":
        # Due to an inconsistency between the way LoRa handles
        # "DokumentVariantEgenskaber" and the specs' we will have to do
        #  this for now, i.e. we allow any JSON-object for "Dokument".
        return {"type": "object"}
    required = ["attributter", "tilstande"] if do_create else []
    schema = _generate_schema_object(
        {
            "attributter": _generate_attributter(obj, do_create),
            "tilstande": _generate_tilstande(obj, do_create),
            "relationer": _generate_relationer(obj, do_create),
            "note": STRING,
            "livscyklus": STRING,
        },
        required,
    )

    schema["$schema"] = "http://json-schema.org/schema#"
    schema["id"] = "http://github.com/magenta-aps/mox"

    schema["definitions"] = {
        "urn": {"type": "string", "pattern": "^urn:."},
        "uuid": {
            "type": "string",
            "pattern": "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-"
            "[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$",
        },
        "empty_string": {"type": "string", "pattern": "^$"},
        "virkning": _generate_schema_object(
            {
                "from": STRING,
                "to": STRING,
                "from_included": BOOLEAN,
                "to_included": BOOLEAN,
                "aktoerref": {"$ref": "#/definitions/uuid"},
                "aktoertypekode": STRING,
                "notetekst": STRING,
            },
            ["from", "to"],
        ),
        "offentlighedundtaget": _generate_schema_object(
            {"alternativtitel": STRING, "hjemmel": STRING},
            ["alternativtitel", "hjemmel"],
        ),
    }

    return schema


SCHEMAS = {}


def get_schema(obj_type, do_create=True):
    try:
        return SCHEMAS[do_create, obj_type]
    except KeyError:
        pass
    schema = SCHEMAS[do_create, obj_type] = copy.deepcopy(
        generate_json_schema(obj_type, do_create)
    )

    return schema


def validate(input_json, obj_type, do_create=True):
    """
    Validate request JSON according to JSON schema.
    :param input_json: The request JSON
    :raise jsonschema.exceptions.ValidationError: If the request JSON is not
    valid according to the JSON schema.
    """
    schema = get_schema(obj_type, do_create)
    jsonschema.validate(input_json, schema)
