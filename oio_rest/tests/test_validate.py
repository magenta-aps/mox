import copy
import json
import os.path
import unittest

import jsonschema

import oio_rest.validate as validate


class TestGenerateTilstande(unittest.TestCase):
    maxDiff = None

    def setUp(self):
        self.relation_nul_til_mange = {
            'type': 'array',
            'items': {
                'type': 'object',
                'properties': {
                    'uuid': {
                        'type': 'string',
                        'pattern': '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-'
                                   '[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-'
                                   '[a-fA-F0-9]{12}$'
                    },
                    'virkning': {'$ref': '#/definitions/virkning'},
                    'objekttype': {'type': 'string'}
                },
                'required': ['uuid', 'virkning'],
                'additionalProperties': False
            },
        }
        self.relation_nul_til_en = copy.copy(self.relation_nul_til_mange)
        self.relation_nul_til_en['maxItems'] = 1

    def _json_to_dict(self, filename):
        """
        Load a JSON file from /interface_test/test_data and return it as JSON
        :param filename: The filename e.g. 'facet_opret.json'
        :return: Dictionary representing the JSON file
        """
        json_file = os.path.join(
            (os.path.dirname(os.path.dirname(os.path.dirname(__file__)))),
            'interface_test', 'test_data', filename)
        with open(json_file) as fp:
            return json.load(fp)

    def test_tilstande_organisation(self):
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'organisationgyldighed': {
                        'type': 'array',
                        'items': {
                            'type': 'object',
                            'properties': {
                                'gyldighed': {
                                    'type': 'string',
                                    'enum': ['Aktiv', 'Inaktiv']
                                },
                                'virkning': {'$ref': '#/definitions/virkning'},
                            },
                            'required': ['gyldighed', 'virkning'],
                            'additionalProperties': False
                        }
                    }
                },
                'required': ['organisationgyldighed'],
                'additionalProperties': False
            },
            validate._generate_tilstande('organisation')
        )

    def test_tilstande_bruger(self):
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'brugergyldighed': {
                        'type': 'array',
                        'items': {
                            'type': 'object',
                            'properties': {
                                'gyldighed': {
                                    'type': 'string',
                                    'enum': ['Aktiv', 'Inaktiv']
                                },
                                'virkning': {'$ref': '#/definitions/virkning'},
                            },
                            'required': ['gyldighed', 'virkning'],
                            'additionalProperties': False
                        }
                    }
                },
                'required': ['brugergyldighed'],
                'additionalProperties': False
            },
            validate._generate_tilstande('bruger')
        )

    def test_tilstande_klassifikation(self):
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'klassifikationpubliceret': {
                        'type': 'array',
                        'items': {
                            'type': 'object',
                            'properties': {
                                'publiceret': {
                                    'type': 'string',
                                    'enum': ['Publiceret', 'IkkePubliceret']
                                },
                                'virkning': {'$ref': '#/definitions/virkning'},
                            },
                            'required': ['publiceret', 'virkning'],
                            'additionalProperties': False
                        }
                    }
                },
                'required': ['klassifikationpubliceret'],
                'additionalProperties': False
            },
            validate._generate_tilstande('klassifikation')
        )

    def test_relationer_facet(self):
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'ansvarlig': self.relation_nul_til_en,
                    'ejer': self.relation_nul_til_en,
                    'facettilhoerer': self.relation_nul_til_en,
                    'redaktoerer': self.relation_nul_til_mange,
                },
                'additionalProperties': False
            },
            validate._generate_relationer('facet')
        )

    def test_relationer_klassifikation(self):
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'ansvarlig': self.relation_nul_til_en,
                    'ejer': self.relation_nul_til_en,
                },
                'additionalProperties': False
            },
            validate._generate_relationer('klassifikation')
        )

    def test_attributter_organisation(self):
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'organisationegenskaber': {
                        'type': 'array',
                        'items': {
                            'type': 'object',
                            'properties': {
                                'brugervendtnoegle': {'type': 'string'},
                                'organisationsnavn': {'type': 'string'},
                                'virkning': {'$ref': '#/definitions/virkning'}
                            },
                            'required': ['brugervendtnoegle', 'virkning'],
                            'additionalProperties': False
                        }
                    }
                },
                'required': ['organisationegenskaber'],
                'additionalProperties': False
            },
            validate._generate_attributter('organisation')
        )

    def test_attributter_bruger(self):
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'brugeregenskaber': {
                        'type': 'array',
                        'items': {
                            'type': 'object',
                            'properties': {
                                'brugervendtnoegle': {'type': 'string'},
                                'brugernavn': {'type': 'string'},
                                'brugertype': {'type': 'string'},
                                'virkning': {'$ref': '#/definitions/virkning'}
                            },
                            'required': ['brugervendtnoegle', 'virkning'],
                            'additionalProperties': False
                        }
                    }
                },
                'required': ['brugeregenskaber'],
                'additionalProperties': False
            },
            validate._generate_attributter('bruger')
        )

    def test_attributter_klasse(self):
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'klasseegenskaber': {
                        'type': 'array',
                        'items': {
                            'type': 'object',
                            'properties': {
                                'brugervendtnoegle': {'type': 'string'},
                                'beskrivelse': {'type': 'string'},
                                'eksempel': {'type': 'string'},
                                'omfang': {'type': 'string'},
                                'titel': {'type': 'string'},
                                'retskilde': {'type': 'string'},
                                'aendringsnotat': {'type': 'string'},
                                'soegeord': {
                                    'type': 'array',
                                    'items': {
                                        'type': 'array',
                                        'items': {'type': 'string'}
                                    },
                                    'maxItems': 2
                                },
                                'virkning': {'$ref': '#/definitions/virkning'}
                            },
                            'required': ['brugervendtnoegle', 'titel',
                                         'virkning'],
                            'additionalProperties': False
                        }
                    }
                },
                'required': ['klasseegenskaber'],
                'additionalProperties': False
            },
            validate._generate_attributter('klasse')
        )

    def test_object_type_is_organisation(self):
        quasi_org = {
            'attributter': {
                "organisationegenskaber": []
            }
        }

        self.assertEqual('organisation', validate._get_object_type(quasi_org))

    def test_object_type_is_organisationenhed(self):
        quasi_org_enhed = {
            'attributter': {
                "organisationenhedegenskaber": []
            }
        }

        self.assertEqual('organisationenhed',
                         validate._get_object_type(quasi_org_enhed))

    def test_create_facet_request_valid(self):
        req = self._json_to_dict('facet_opret.json')
        jsonschema.validate(req, validate.generate_json_schema(req))

    def test_create_facet_request_invalid(self):
        req = self._json_to_dict('facet_opret.json')

        # Change JSON key to invalid value
        req['attributter']['facetegenskaber'][0]['xyz_supplement'] = \
            req['attributter']['facetegenskaber'][0].pop('supplement')

        with self.assertRaises(jsonschema.exceptions.ValidationError):
            jsonschema.validate(req, validate.generate_json_schema(req)),

    def test_create_bruger_request_valid(self):
        req = self._json_to_dict('bruger_opret.json')
        jsonschema.validate(req, validate.generate_json_schema(req))

    def test_create_klassifikation_request_valid(self):
        req = self._json_to_dict('klassifikation_opret.json')
        jsonschema.validate(req, validate.generate_json_schema(req))

    def test_create_klasse_request_valid(self):
        req = self._json_to_dict('klasse_opret.json')
        jsonschema.validate(req, validate.generate_json_schema(req))

    # def test_create_aktivitet_request_valid(self):
    #     req = self._json_to_dict('aktivitet_opret.json')
    #     jsonschema.validate(req, validate.generate_json_schema(req))
