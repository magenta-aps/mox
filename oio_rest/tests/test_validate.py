# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


import copy
import json
import os.path
import unittest

import jsonschema
import flask_testing

from oio_rest import aktivitet
from oio_rest import app
from oio_rest import db
from oio_rest import dokument
from oio_rest import indsats
from oio_rest import klassifikation
from oio_rest import log
from oio_rest import oio_base
from oio_rest import organisation
from oio_rest import sag
from oio_rest import tilstand
from oio_rest import validate

from . import util


class TestBase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()

        # once per class will suffice, since none of them touch the db
        # structure
        validate.SCHEMAS = {}

    @classmethod
    def tearDownClass(cls):
        super().setUpClass()

        # once per class will suffice, since none of them touch the db
        # structure
        validate.SCHEMAS = {}


class TestGetMandatory(TestBase):
    def test_facet(self):
        self.assertEqual(
            ["brugervendtnoegle"], validate._get_mandatory("facet", "egenskaber")
        )

    def test_organisation(self):
        self.assertEqual(
            ["brugervendtnoegle"], validate._get_mandatory("organisation", "egenskaber")
        )

    def test_klasse(self):
        self.assertEqual(
            ["brugervendtnoegle", "titel"],
            validate._get_mandatory("klasse", "egenskaber"),
        )

    def test_sag(self):
        self.assertEqual(
            [
                "beskrivelse",
                "brugervendtnoegle",
                "kassationskode",
                "sagsnummer",
                "titel",
            ],
            validate._get_mandatory("sag", "egenskaber"),
        )

    def test_dokument(self):
        self.assertEqual(
            ["beskrivelse", "brevdato", "brugervendtnoegle", "dokumenttype", "titel"],
            validate._get_mandatory("dokument", "egenskaber"),
        )

    def test_loghaendelse(self):
        self.assertEqual(
            ["tidspunkt"], validate._get_mandatory("loghaendelse", "egenskaber")
        )


class TestGenerateJSONSchema(TestBase):
    maxDiff = None

    def setUp(self):
        super().setUp()

        self.relation_nul_til_mange = {
            "type": "array",
            "items": {
                "oneOf": [
                    {
                        "type": "object",
                        "properties": {
                            "uuid": {"$ref": "#/definitions/uuid"},
                            "virkning": {"$ref": "#/definitions/virkning"},
                            "objekttype": {"type": "string"},
                        },
                        "required": ["uuid", "virkning"],
                        "additionalProperties": False,
                    },
                    {
                        "type": "object",
                        "properties": {
                            "urn": {"$ref": "#/definitions/urn"},
                            "virkning": {"$ref": "#/definitions/virkning"},
                            "objekttype": {"type": "string"},
                        },
                        "required": ["urn", "virkning"],
                        "additionalProperties": False,
                    },
                    {
                        "type": "object",
                        "properties": {
                            "urn": {"$ref": "#/definitions/empty_string"},
                            "uuid": {"$ref": "#/definitions/empty_string"},
                            "virkning": {"$ref": "#/definitions/virkning"},
                        },
                        "required": ["urn", "uuid", "virkning"],
                        "additionalProperties": False,
                    },
                ]
            },
        }

        self.relation_nul_til_en = copy.deepcopy(self.relation_nul_til_mange)
        self.relation_nul_til_en["maxItems"] = 1

    def _json_to_dict(self, filename):
        """
        Load a JSON file from ``tests/fixtures`` and return it as JSON.

        :param filename: The filename e.g. 'facet_opret.json'
        :return: Dictionary representing the JSON file
        """
        json_file = os.path.join(os.path.dirname(__file__), "fixtures", filename)
        with open(json_file) as fp:
            return json.load(fp)

    def test_tilstande_organisation(self):
        expected = {
            "type": "object",
            "properties": {
                "organisationgyldighed": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "gyldighed": {
                                "type": "string",
                                "enum": ["Aktiv", "Inaktiv"],
                            },
                            "virkning": {"$ref": "#/definitions/virkning"},
                        },
                        "required": ["gyldighed", "virkning"],
                        "additionalProperties": False,
                    },
                }
            },
            "required": ["organisationgyldighed"],
            "additionalProperties": False,
        }
        self.assertEqual(
            expected, validate._generate_tilstande("organisation", do_create=True)
        )

        del expected["required"]
        self.assertEqual(
            expected, validate._generate_tilstande("organisation", do_create=False)
        )

    def test_tilstande_bruger(self):
        self.assertEqual(
            {
                "type": "object",
                "properties": {
                    "brugergyldighed": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "gyldighed": {
                                    "type": "string",
                                    "enum": ["Aktiv", "Inaktiv"],
                                },
                                "virkning": {"$ref": "#/definitions/virkning"},
                            },
                            "required": ["gyldighed", "virkning"],
                            "additionalProperties": False,
                        },
                    }
                },
                "required": ["brugergyldighed"],
                "additionalProperties": False,
            },
            validate._generate_tilstande("bruger", do_create=True),
        )

    def test_tilstande_klassifikation(self):
        self.assertEqual(
            {
                "type": "object",
                "properties": {
                    "klassifikationpubliceret": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "publiceret": {
                                    "type": "string",
                                    "enum": ["Publiceret", "IkkePubliceret"],
                                },
                                "virkning": {"$ref": "#/definitions/virkning"},
                            },
                            "required": ["publiceret", "virkning"],
                            "additionalProperties": False,
                        },
                    }
                },
                "required": ["klassifikationpubliceret"],
                "additionalProperties": False,
            },
            validate._generate_tilstande("klassifikation", do_create=True),
        )

    def test_relationer_facet(self):
        self.assertEqual(
            {
                "type": "object",
                "properties": {
                    "ansvarlig": self.relation_nul_til_en,
                    "ejer": self.relation_nul_til_en,
                    "facettilhoerer": self.relation_nul_til_en,
                    "redaktoerer": self.relation_nul_til_mange,
                },
                "additionalProperties": False,
            },
            validate._generate_relationer("facet", do_create=True),
        )

    def test_relationer_klassifikation(self):
        self.assertEqual(
            {
                "type": "object",
                "properties": {
                    "ansvarlig": self.relation_nul_til_en,
                    "ejer": self.relation_nul_til_en,
                },
                "additionalProperties": False,
            },
            validate._generate_relationer("klassifikation", do_create=True),
        )

    def test_relationer_aktivitet(self):
        aktoerattr = {
            "aktoerattr": {
                "type": "object",
                "properties": {
                    "accepteret": {"type": "string"},
                    "obligatorisk": {"type": "string"},
                    "repraesentation_uuid": {"$ref": "#/definitions/uuid"},
                },
                "required": ["accepteret", "obligatorisk", "repraesentation_uuid"],
                "additionalProperties": False,
            }
        }
        self.relation_nul_til_en["items"]["oneOf"][0]["properties"].update(
            copy.deepcopy(aktoerattr)
        )
        self.relation_nul_til_en["items"]["oneOf"][1]["properties"].update(
            copy.deepcopy(aktoerattr)
        )
        aktoerattr["indeks"] = {"type": "integer"}
        self.relation_nul_til_mange["items"]["oneOf"][0]["properties"].update(
            aktoerattr
        )
        self.relation_nul_til_mange["items"]["oneOf"][1]["properties"].update(
            aktoerattr
        )

        self.assertEqual(
            {
                "type": "object",
                "properties": {
                    "aktivitetstype": self.relation_nul_til_en,
                    "emne": self.relation_nul_til_en,
                    "foelsomhedklasse": self.relation_nul_til_en,
                    "ansvarligklasse": self.relation_nul_til_en,
                    "rekvirentklasse": self.relation_nul_til_en,
                    "ansvarlig": self.relation_nul_til_en,
                    "tilhoerer": self.relation_nul_til_en,
                    "udfoererklasse": self.relation_nul_til_mange,
                    "deltagerklasse": self.relation_nul_til_mange,
                    "objektklasse": self.relation_nul_til_mange,
                    "resultatklasse": self.relation_nul_til_mange,
                    "grundlagklasse": self.relation_nul_til_mange,
                    "facilitetklasse": self.relation_nul_til_mange,
                    "adresse": self.relation_nul_til_mange,
                    "geoobjekt": self.relation_nul_til_mange,
                    "position": self.relation_nul_til_mange,
                    "facilitet": self.relation_nul_til_mange,
                    "lokale": self.relation_nul_til_mange,
                    "aktivitetdokument": self.relation_nul_til_mange,
                    "aktivitetgrundlag": self.relation_nul_til_mange,
                    "aktivitetresultat": self.relation_nul_til_mange,
                    "udfoerer": self.relation_nul_til_mange,
                    "deltager": self.relation_nul_til_mange,
                },
                "additionalProperties": False,
            },
            validate._generate_relationer("aktivitet", do_create=False),
        )

    def test_relationer_indsats(self):
        self.relation_nul_til_mange["items"]["oneOf"][0]["properties"]["indeks"] = {
            "type": "integer"
        }
        self.relation_nul_til_mange["items"]["oneOf"][1]["properties"]["indeks"] = {
            "type": "integer"
        }
        self.assertEqual(
            {
                "type": "object",
                "properties": {
                    "indsatsmodtager": self.relation_nul_til_en,
                    "indsatstype": self.relation_nul_til_en,
                    "indsatskvalitet": self.relation_nul_til_mange,
                    "indsatsaktoer": self.relation_nul_til_mange,
                    "samtykke": self.relation_nul_til_mange,
                    "indsatssag": self.relation_nul_til_mange,
                    "indsatsdokument": self.relation_nul_til_mange,
                },
                "additionalProperties": False,
            },
            validate._generate_relationer("indsats", do_create=True),
        )

    def test_relationer_tilstand(self):
        self.relation_nul_til_mange["items"]["oneOf"][0]["properties"]["indeks"] = {
            "type": "integer"
        }
        self.relation_nul_til_mange["items"]["oneOf"][1]["properties"]["indeks"] = {
            "type": "integer"
        }
        self.assertEqual(
            {
                "type": "object",
                "properties": {
                    "tilstandsobjekt": self.relation_nul_til_en,
                    "tilstandstype": self.relation_nul_til_en,
                    "begrundelse": self.relation_nul_til_mange,
                    "tilstandskvalitet": self.relation_nul_til_mange,
                    "tilstandsvurdering": self.relation_nul_til_mange,
                    "tilstandsaktoer": self.relation_nul_til_mange,
                    "tilstandsudstyr": self.relation_nul_til_mange,
                    "samtykke": self.relation_nul_til_mange,
                    "tilstandsdokument": self.relation_nul_til_mange,
                    "tilstandsvaerdi": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "indeks": {"type": "integer"},
                                "tilstandsvaerdiattr": {
                                    "type": "object",
                                    "properties": {
                                        "forventet": {"type": "boolean"},
                                        "nominelvaerdi": {"type": "string"},
                                    },
                                    "required": ["forventet", "nominelvaerdi"],
                                    "additionalProperties": False,
                                },
                                "virkning": {"$ref": "#/definitions/virkning"},
                                "objekttype": {"type": "string"},
                            },
                            "required": ["virkning"],
                            "additionalProperties": False,
                        },
                    },
                },
                "additionalProperties": False,
            },
            validate._generate_relationer("tilstand", do_create=True),
        )

    def test_relationer_sag(self):
        self.relation_nul_til_mange["items"]["oneOf"][0]["properties"]["indeks"] = {
            "type": "integer"
        }
        self.relation_nul_til_mange["items"]["oneOf"][1]["properties"]["indeks"] = {
            "type": "integer"
        }
        self.assertEqual(
            {
                "type": "object",
                "properties": {
                    "behandlingarkiv": self.relation_nul_til_en,
                    "afleveringsarkiv": self.relation_nul_til_en,
                    "primaerklasse": self.relation_nul_til_en,
                    "opgaveklasse": self.relation_nul_til_en,
                    "handlingsklasse": self.relation_nul_til_en,
                    "kontoklasse": self.relation_nul_til_en,
                    "sikkerhedsklasse": self.relation_nul_til_en,
                    "foelsomhedsklasse": self.relation_nul_til_en,
                    "indsatsklasse": self.relation_nul_til_en,
                    "ydelsesklasse": self.relation_nul_til_en,
                    "ejer": self.relation_nul_til_en,
                    "ansvarlig": self.relation_nul_til_en,
                    "primaerbehandler": self.relation_nul_til_en,
                    "udlaanttil": self.relation_nul_til_en,
                    "primaerpart": self.relation_nul_til_en,
                    "ydelsesmodtager": self.relation_nul_til_en,
                    "oversag": self.relation_nul_til_en,
                    "praecedens": self.relation_nul_til_en,
                    "afgiftsobjekt": self.relation_nul_til_en,
                    "ejendomsskat": self.relation_nul_til_en,
                    "andetarkiv": self.relation_nul_til_mange,
                    "andrebehandlere": self.relation_nul_til_mange,
                    "sekundaerpart": self.relation_nul_til_mange,
                    "andresager": self.relation_nul_til_mange,
                    "byggeri": self.relation_nul_til_mange,
                    "fredning": self.relation_nul_til_mange,
                    "journalpost": {
                        "type": "array",
                        "items": {
                            "oneOf": [
                                {
                                    "type": "object",
                                    "properties": {
                                        "indeks": {"type": "integer"},
                                        "journaldokument": {
                                            "type": "object",
                                            "properties": {
                                                "dokumenttitel": {"type": "string"},
                                                "offentlighedundtaget": {
                                                    "$ref": "#/definitions/"
                                                    "offentlighed"
                                                    "undtaget"
                                                },
                                            },
                                            "required": [
                                                "dokumenttitel",
                                                "offentlighedundtaget",
                                            ],
                                            "additionalProperties": False,
                                        },
                                        "journalnotat": {
                                            "type": "object",
                                            "properties": {
                                                "format": {"type": "string"},
                                                "notat": {"type": "string"},
                                                "titel": {"type": "string"},
                                            },
                                            "required": ["titel", "notat", "format"],
                                            "additionalProperties": False,
                                        },
                                        "journalpostkode": {
                                            "type": "string",
                                            "enum": ["journalnotat", "vedlagtdokument"],
                                        },
                                        "uuid": {"$ref": "#/definitions/uuid"},
                                        "virkning": {"$ref": "#/definitions/virkning"},
                                        "objekttype": {"type": "string"},
                                    },
                                    "required": ["uuid", "virkning", "journalpostkode"],
                                    "additionalProperties": False,
                                },
                                {
                                    "type": "object",
                                    "properties": {
                                        "indeks": {"type": "integer"},
                                        "journaldokument": {
                                            "type": "object",
                                            "properties": {
                                                "dokumenttitel": {"type": "string"},
                                                "offentlighedundtaget": {
                                                    "$ref": "#/definitions/"
                                                    "offentlighed"
                                                    "undtaget"
                                                },
                                            },
                                            "required": [
                                                "dokumenttitel",
                                                "offentlighedundtaget",
                                            ],
                                            "additionalProperties": False,
                                        },
                                        "journalnotat": {
                                            "type": "object",
                                            "properties": {
                                                "format": {"type": "string"},
                                                "notat": {"type": "string"},
                                                "titel": {"type": "string"},
                                            },
                                            "required": ["titel", "notat", "format"],
                                            "additionalProperties": False,
                                        },
                                        "journalpostkode": {
                                            "type": "string",
                                            "enum": ["journalnotat", "vedlagtdokument"],
                                        },
                                        "urn": {"$ref": "#/definitions/urn"},
                                        "virkning": {"$ref": "#/definitions/virkning"},
                                        "objekttype": {"type": "string"},
                                    },
                                    "required": ["urn", "virkning", "journalpostkode"],
                                    "additionalProperties": False,
                                },
                                {
                                    "type": "object",
                                    "properties": {
                                        "urn": {"$ref": "#/definitions/empty_string"},
                                        "uuid": {"$ref": "#/definitions/empty_string"},
                                        "virkning": {"$ref": "#/definitions/virkning"},
                                    },
                                    "required": ["urn", "uuid", "virkning"],
                                    "additionalProperties": False,
                                },
                            ]
                        },
                    },
                },
                "additionalProperties": False,
            },
            validate._generate_relationer("sag", do_create=True),
        )

    def test_attributter_organisation(self):
        self.assertEqual(
            {
                "type": "object",
                "properties": {
                    "organisationegenskaber": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "brugervendtnoegle": {"type": "string"},
                                "organisationsnavn": {"type": "string"},
                                "integrationsdata": {"type": "string"},
                                "virkning": {"$ref": "#/definitions/virkning"},
                            },
                            "required": ["brugervendtnoegle", "virkning"],
                            "additionalProperties": False,
                        },
                    }
                },
                "required": ["organisationegenskaber"],
                "additionalProperties": False,
            },
            validate._generate_attributter("organisation", do_create=True),
        )

    def test_attributter_bruger(self):
        self.assertEqual(
            {
                "type": "object",
                "properties": {
                    "brugeregenskaber": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "brugervendtnoegle": {"type": "string"},
                                "brugernavn": {"type": "string"},
                                "brugertype": {"type": "string"},
                                "integrationsdata": {"type": "string"},
                                "virkning": {"$ref": "#/definitions/virkning"},
                            },
                            "required": ["brugervendtnoegle", "virkning"],
                            "additionalProperties": False,
                        },
                    }
                },
                "required": ["brugeregenskaber"],
                "additionalProperties": False,
            },
            validate._generate_attributter("bruger", do_create=True),
        )

    def test_attributter_klasse(self):
        expected = {
            "type": "object",
            "properties": {
                "klasseegenskaber": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "brugervendtnoegle": {"type": "string"},
                            "beskrivelse": {"type": "string"},
                            "eksempel": {"type": "string"},
                            "omfang": {"type": "string"},
                            "titel": {"type": "string"},
                            "retskilde": {"type": "string"},
                            "aendringsnotat": {"type": "string"},
                            "integrationsdata": {"type": "string"},
                            "soegeord": {
                                "type": "array",
                                "items": {"type": "array", "items": {"type": "string"}},
                                "maxItems": 2,
                            },
                            "virkning": {"$ref": "#/definitions/virkning"},
                        },
                        "required": ["brugervendtnoegle", "titel", "virkning"],
                        "additionalProperties": False,
                    },
                }
            },
            "required": ["klasseegenskaber"],
            "additionalProperties": False,
        }
        self.assertEqual(
            expected, validate._generate_attributter("klasse", do_create=True)
        )

        del expected["required"]
        expected["properties"]["klasseegenskaber"]["items"]["required"] = ["virkning"]
        self.assertEqual(
            expected, validate._generate_attributter("klasse", do_create=False)
        )

    def test_attributter_itsystem(self):
        self.assertEqual(
            {
                "type": "object",
                "properties": {
                    "itsystemegenskaber": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "brugervendtnoegle": {"type": "string"},
                                "itsystemnavn": {"type": "string"},
                                "itsystemtype": {"type": "string"},
                                "konfigurationreference": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                },
                                "integrationsdata": {"type": "string"},
                                "virkning": {"$ref": "#/definitions/virkning"},
                            },
                            "required": ["brugervendtnoegle", "virkning"],
                            "additionalProperties": False,
                        },
                    }
                },
                "required": ["itsystemegenskaber"],
                "additionalProperties": False,
            },
            validate._generate_attributter("itsystem", do_create=True),
        )

    def test_attributter_sag(self):
        self.assertEqual(
            {
                "type": "object",
                "properties": {
                    "sagegenskaber": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "brugervendtnoegle": {"type": "string"},
                                "sagsnummer": {"type": "string"},
                                "titel": {"type": "string"},
                                "beskrivelse": {"type": "string"},
                                "hjemmel": {"type": "string"},
                                "offentlighedundtaget": {
                                    "$ref": "#/definitions/" "offentlighedundtaget"
                                },
                                "principiel": {"type": "boolean"},
                                "kassationskode": {"type": "string"},
                                "afleveret": {"type": "boolean"},
                                "integrationsdata": {"type": "string"},
                                "virkning": {"$ref": "#/definitions/virkning"},
                            },
                            "required": [
                                "beskrivelse",
                                "brugervendtnoegle",
                                "kassationskode",
                                "sagsnummer",
                                "titel",
                                "virkning",
                            ],
                            "additionalProperties": False,
                        },
                    }
                },
                "required": ["sagegenskaber"],
                "additionalProperties": False,
            },
            validate._generate_attributter("sag", do_create=True),
        )

    def test_attributter_dokument(self):
        self.assertEqual(
            {
                "type": "object",
                "properties": {
                    "dokumentegenskaber": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "brugervendtnoegle": {"type": "string"},
                                "beskrivelse": {"type": "string"},
                                "brevdato": {"type": "string"},
                                "dokumenttype": {"type": "string"},
                                "kassationskode": {"type": "string"},
                                "major": {"type": "integer"},
                                "minor": {"type": "integer"},
                                "offentlighedundtaget": {
                                    "$ref": "#/definitions/" "offentlighedundtaget"
                                },
                                "titel": {"type": "string"},
                                "integrationsdata": {"type": "string"},
                                "virkning": {"$ref": "#/definitions/virkning"},
                            },
                            "required": [
                                "beskrivelse",
                                "brevdato",
                                "brugervendtnoegle",
                                "dokumenttype",
                                "titel",
                                "virkning",
                            ],
                            "additionalProperties": False,
                        },
                    }
                },
                "required": ["dokumentegenskaber"],
                "additionalProperties": False,
            },
            validate._generate_attributter("dokument", do_create=True),
        )

    def test_index_allowed_in_relations_for_aktivitet(self):
        relationer = validate._generate_relationer("aktivitet", do_create=True)
        self.assertEqual(
            {"type": "integer"},
            relationer["properties"]["deltager"]["items"]["oneOf"][0]["properties"][
                "indeks"
            ],
        )
        self.assertEqual(
            {"type": "integer"},
            relationer["properties"]["deltager"]["items"]["oneOf"][1]["properties"][
                "indeks"
            ],
        )

    def test_index_allowed_in_relations_for_sag(self):
        relationer = validate._generate_relationer("sag", do_create=True)
        self.assertEqual(
            {"type": "integer"},
            relationer["properties"]["andrebehandlere"]["items"]["oneOf"][0][
                "properties"
            ]["indeks"],
        )
        self.assertEqual(
            {"type": "integer"},
            relationer["properties"]["andrebehandlere"]["items"]["oneOf"][1][
                "properties"
            ]["indeks"],
        )

    def test_index_allowed_in_relations_for_tilstand(self):
        relationer = validate._generate_relationer("tilstand", do_create=True)
        self.assertEqual(
            {"type": "integer"},
            relationer["properties"]["samtykke"]["items"]["oneOf"][0]["properties"][
                "indeks"
            ],
        )
        self.assertEqual(
            {"type": "integer"},
            relationer["properties"]["samtykke"]["items"]["oneOf"][1]["properties"][
                "indeks"
            ],
        )

    def test_index_allowed_in_relations_for_indsats(self):
        relationer = validate._generate_relationer("indsats", do_create=True)
        self.assertEqual(
            {"type": "integer"},
            relationer["properties"]["samtykke"]["items"]["oneOf"][0]["properties"][
                "indeks"
            ],
        )
        self.assertEqual(
            {"type": "integer"},
            relationer["properties"]["samtykke"]["items"]["oneOf"][1]["properties"][
                "indeks"
            ],
        )

    def test_index_not_allowed_for_non_special_nul_til_mange_relations(self):
        relationer = validate._generate_relationer("organisation", do_create=True)
        self.assertFalse(
            "indeks"
            in relationer["properties"]["ansatte"]["items"]["oneOf"][0]["properties"]
        )
        self.assertFalse(
            "indeks"
            in relationer["properties"]["ansatte"]["items"]["oneOf"][1]["properties"]
        )

    def test_create_request_valid(self):
        for obj in db.db_structure.REAL_DB_STRUCTURE:
            with self.subTest(obj):
                req = self._json_to_dict("{}_opret.json".format(obj))
                validate.validate(req, obj)

    def test_create_facet_request_invalid(self):
        req = self._json_to_dict("facet_opret.json")

        # Change JSON key to invalid value
        req["attributter"]["facetegenskaber"][0]["xyz_supplement"] = req["attributter"][
            "facetegenskaber"
        ][0].pop("supplement")

        with self.assertRaises(jsonschema.exceptions.ValidationError):
            obj = "facet"
            validate.validate(req, obj)

    def test_create_misdirected_invalid(self):
        req = self._json_to_dict("facet_opret.json")

        # note: 'klasse' ≠ 'facet'!
        with self.assertRaises(jsonschema.exceptions.ValidationError):
            validate.validate(req, "klasse")


class TestFacetSystematically(TestBase):
    def setUp(self):
        super().setUp()

        self.standard_virkning1 = {
            "from": "2000-01-01 12:00:00+01",
            "from_included": True,
            "to": "2020-01-01 12:00:00+01",
            "to_included": False,
        }
        self.standard_virkning2 = {
            "from": "2020-01-01 12:00:00+01",
            "from_included": True,
            "to": "2030-01-01 12:00:00+01",
            "to_included": False,
        }
        self.reference = {
            "uuid": "00000000-0000-0000-0000-000000000000",
            "virkning": self.standard_virkning1,
        }
        self.facet = {
            "attributter": {
                "facetegenskaber": [
                    {"brugervendtnoegle": "bvn1", "virkning": self.standard_virkning1}
                ]
            },
            "tilstande": {
                "facetpubliceret": [
                    {"publiceret": "Publiceret", "virkning": self.standard_virkning1}
                ]
            },
        }

    def assertValidationError(self):
        with self.assertRaises(jsonschema.exceptions.ValidationError):
            jsonschema.validate(self.facet, validate.get_schema("facet"))

    def test_valid_equivalence_classes1(self):
        """
        Equivalence classes covered: [44][48][80][53][77][79][83][86][89][92]
        [61][63][67][68][101][102][108][109][111]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        jsonschema.validate(self.facet, validate.get_schema("facet"))

    def test_valid_equivalence_classes2(self):
        """
        Equivalence classes covered: [45][50][81][84][87][90][93][55][62]
        [64][69]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["note"] = "This is a note"
        egenskaber = self.facet["attributter"]["facetegenskaber"][0]
        egenskaber["beskrivelse"] = "xyz"
        egenskaber["plan"] = "xyz"
        egenskaber["opbygning"] = "xyz"
        egenskaber["ophavsret"] = "xyz"
        egenskaber["supplement"] = "xyz"
        egenskaber["retskilde"] = "xyz"

        self.facet["attributter"]["facetegenskaber"].append(
            {"brugervendtnoegle": "bvn2", "virkning": self.standard_virkning2}
        )

        self.facet["tilstande"]["facetpubliceret"].append(
            {"publiceret": "IkkePubliceret", "virkning": self.standard_virkning2}
        )

        self.facet["relationer"] = {}

        jsonschema.validate(self.facet, validate.get_schema("facet"))

    def test_valid_equivalence_classes3(self):
        """
        Equivalence classes covered: [70][72]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["relationer"] = {"ansvarlig": []}

        jsonschema.validate(self.facet, validate.get_schema("facet"))

    def test_valid_equivalence_classes4(self):
        """
        Equivalence classes covered: [71][74][76][112]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        urn = {"urn": "urn:This is an URN", "virkning": self.standard_virkning1}
        self.facet["relationer"] = {
            "ansvarlig": [self.reference],
            "ejer": [urn],
            "facettilhoerer": [self.reference],
            "redaktoerer": [self.reference, urn],
        }

        jsonschema.validate(self.facet, validate.get_schema("facet"))

    def test_note_not_string(self):
        """
        Equivalence classes covered: [43]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["note"] = ["This is not a string"]
        self.assertValidationError()

    def test_bvn_missing(self):
        """
        Equivalence classes covered: [46]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet["attributter"]["facetegenskaber"][0]["brugervendtnoegle"]
        self.assertValidationError()

    def test_bvn_not_string(self):
        """
        Equivalence classes covered: [47]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["brugervendtnoegle"] = {
            "dummy": "This is not a string"
        }
        self.assertValidationError()

    def test_beskrivelse_not_string(self):
        """
        Equivalence classes covered: [49]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["beskrivelse"] = {
            "dummy": "This is not a string"
        }
        self.assertValidationError()

    def test_plan_not_string(self):
        """
        Equivalence classes covered: [78]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["plan"] = {
            "dummy": "This is not a string"
        }
        self.assertValidationError()

    def test_opbygning_not_string(self):
        """
        Equivalence classes covered: [82]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["opbygning"] = {
            "dummy": "This is not a string"
        }
        self.assertValidationError()

    def test_ophavsret_not_string(self):
        """
        Equivalence classes covered: [85]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["ophavsret"] = {
            "dummy": "This is not a string"
        }
        self.assertValidationError()

    def test_supplement_not_string(self):
        """
        Equivalence classes covered: [88]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["supplement"] = {
            "dummy": "This is not a string"
        }
        self.assertValidationError()

    def test_retskilde_not_string(self):
        """
        Equivalence classes covered: [91]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["retskilde"] = {
            "dummy": "This is not a string"
        }
        self.assertValidationError()

    def test_virkning_missing_attributter(self):
        """
        Equivalence classes covered: [51]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet["attributter"]["facetegenskaber"][0]["virkning"]
        self.assertValidationError()

    def test_egenskaber_missing(self):
        """
        Equivalence classes covered: [54]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet["attributter"]["facetegenskaber"]
        self.assertValidationError()

    def test_unknown_key_in_facetegenskaber(self):
        """
        Equivalence classes covered: [94]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["unknown"] = "xyz"
        self.assertValidationError()

    def test_empty_facet(self):
        """
        Equivalence classes covered: [56]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet = {}
        self.assertValidationError()

    def test_attributter_missing(self):
        """
        Equivalence classes covered: [57]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet["attributter"]
        self.assertValidationError()

    def test_tilstande_missing(self):
        """
        Equivalence classes covered: [58]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet["tilstande"]
        self.assertValidationError()

    def test_facetpubliceret_missing(self):
        """
        Equivalence classes covered: [60]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet["tilstande"]["facetpubliceret"]
        self.assertValidationError()

    def test_publiceret_not_valid_enum(self):
        """
        Equivalence classes covered: [61]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["tilstande"]["facetpubliceret"][0]["publiceret"] = "invalid"
        self.assertValidationError()

    def test_publiceret_missing(self):
        """
        Equivalence classes covered: [62]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet["tilstande"]["facetpubliceret"][0]["publiceret"]
        self.assertValidationError()

    def test_virkning_malformed_tilstande(self):
        """
        Equivalence classes covered: [66]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet["tilstande"]["facetpubliceret"][0]["virkning"]["from"]
        self.assertValidationError()

    def test_unknown_key_in_facetpubliceret(self):
        """
        Equivalence classes covered: [95]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["tilstande"]["facetpubliceret"][0]["unknown"] = "xyz"
        self.assertValidationError()

    def test_two_references_in_nul_til_en_relation(self):
        """
        Equivalence classes covered: [96]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["relationer"] = {
            "ansvarlig": [self.reference, self.reference],
        }
        self.assertValidationError()

    def test_reference_not_an_uuid(self):
        """
        Equivalence classes covered: [73]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.reference["uuid"] = "This is not an UUID"
        self.facet["relationer"] = {
            "ansvarlig": [self.reference],
        }
        self.assertValidationError()

    def test_urn_reference_not_valid(self):
        """
        Equivalence classes covered: [114]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.reference.pop("uuid")
        self.reference["urn"] = "This is not an URN"
        self.facet["relationer"] = {"ansvarlig": [self.reference]}
        self.assertValidationError()

    def test_uuid_and_urn_not_allowed_simultaneously_in_reference(self):
        """
        Equivalence classes covered: [113]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.reference["urn"] = "urn:This is an URN"
        self.facet["relationer"] = {"ansvarlig": [self.reference]}
        self.assertValidationError()

    def test_unknown_relation_name(self):
        """
        Equivalence classes covered: [75]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["relationer"] = {
            "unknown": [self.reference],
        }
        self.assertValidationError()

    def test_virkning_aktoer_and_note_ok(self):
        """
        Equivalence classes covered: [104][106][110]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["virkning"].update(
            {
                "aktoerref": "00000000-0000-0000-0000-000000000000",
                "aktoertypekode": "type",
                "notetekst": "This is a note",
            }
        )
        jsonschema.validate(self.facet, validate.get_schema("facet"))

    def test_virkning_from_missing(self):
        """
        Equivalence classes covered: [52][97]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet["attributter"]["facetegenskaber"][0]["virkning"]["from"]
        self.assertValidationError()

    def test_virkning_to_missing(self):
        """
        Equivalence classes covered: [99]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet["attributter"]["facetegenskaber"][0]["virkning"]["to"]
        self.assertValidationError()

    def test_virkning_from_not_string(self):
        """
        Equivalence classes covered: [98]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["virkning"]["from"] = {
            "key": "This is not a string"
        }
        self.assertValidationError()

    def test_virkning_to_not_string(self):
        """
        Equivalence classes covered: [100]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["virkning"]["to"] = {
            "key": "This is not a string"
        }
        self.assertValidationError()

    def test_virkning_aktoerref_not_uuid(self):
        """
        Equivalence classes covered: [103]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["virkning"][
            "aktoerref"
        ] = "This is not an UUID"
        self.assertValidationError()

    def test_virkning_aktoertype_not_string(self):
        """
        Equivalence classes covered: [105]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["virkning"][
            "aktoertypekode"
        ] = {"key": "This is not a string"}
        self.assertValidationError()

    def test_virkning_notetekst_not_string(self):
        """
        Equivalence classes covered: [107]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet["attributter"]["facetegenskaber"][0]["virkning"]["notetekst"] = {
            "key": "This is not a string"
        }
        self.assertValidationError()


class TestSchemaEndPoints(flask_testing.TestCase):
    def setUp(self):
        super().setUp()

        validate.SCHEMAS = {}

        # extract a list of all OIO hierarchies and classes
        def get_subclasses(cls):
            for subcls in cls.__subclasses__():
                if subcls.__module__.startswith("oio_rest."):
                    yield subcls
                    yield from get_subclasses(subcls)

        self.hierarchies = list(get_subclasses(oio_base.OIOStandardHierarchy))

    def create_app(self):
        app.config["TESTING"] = True
        return app

    @unittest.expectedFailure
    def test_schemas_unchanged(self):
        """Check that the schema have not changed from last commit. The
        intention of the test is not to force schema stagenation, but to inform
        the developers of schmea changes in commits by updating `schemas.json`.
        """

        expected = util.get_fixture("schemas.json")
        expected_path = os.path.join(util.FIXTURE_DIR, "schemas.json")

        actual = {
            cls.__name__: cls.get_schema().json
            for hier in self.hierarchies
            for cls in hier._classes
        }

        self.assertEqual(
            expected,
            actual,
            "schemas changed. Please update {}".format(expected_path),
        )

    def assertSchemaOK(self, hierarchy):
        """
        Check that the schema endpoints for the classes in the given hierarchy
        respond with HTTP status code 200 and return JSON.
        :param hierarchy: The hierarchy to check, e.g. SagsHierarki,...
        """
        # Careful now - no logic in the test code!

        for obj in hierarchy._classes:
            url = "/{}/{}/schema".format(hierarchy._name.lower(), obj.__name__.lower())
            r = self.client.get(url)
            self.assertEqual(200, r.status_code)
            json.loads(r.data.decode("utf-8"))

    def test_aktivitet_hierarchy(self):
        self.assertSchemaOK(aktivitet.AktivitetsHierarki)

    def test_dokument_hierarchy(self):
        self.assertSchemaOK(dokument.DokumentHierarki)

    def test_indsats_hierarchy(self):
        self.assertSchemaOK(indsats.IndsatsHierarki)

    def test_klassifikation_hierarchy(self):
        self.assertSchemaOK(klassifikation.KlassifikationsHierarki)

    def test_log_hierarchy(self):
        self.assertSchemaOK(log.LogHierarki)

    def test_organisation_hierarchy(self):
        self.assertSchemaOK(organisation.OrganisationsHierarki)

    def test_sag_hierarchy(self):
        self.assertSchemaOK(sag.SagsHierarki)

    def test_tilstand_hierarchy(self):
        self.assertSchemaOK(tilstand.TilstandsHierarki)
