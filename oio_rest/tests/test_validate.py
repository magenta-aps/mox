import copy
import json
import os.path
import unittest
import jsonschema

import oio_rest.validate as validate


class TestGetMandatory(unittest.TestCase):
    def test_facet(self):
        self.assertEqual(
            ['brugervendtnoegle'],
            validate._get_mandatory('facet', 'egenskaber')
        )

    def test_organisation(self):
        self.assertEqual(
            ['brugervendtnoegle'],
            validate._get_mandatory('organisation', 'egenskaber')
        )

    def test_klasse(self):
        self.assertEqual(
            ['brugervendtnoegle', 'titel'],
            validate._get_mandatory('klasse', 'egenskaber')
        )

    def test_sag(self):
        self.assertEqual(
            ['beskrivelse', 'brugervendtnoegle', 'kassationskode',
             'sagsnummer', 'titel'],
            validate._get_mandatory('sag', 'egenskaber')
        )

    def test_dokument(self):
        self.assertEqual(
            ['beskrivelse', 'brevdato', 'brugervendtnoegle', 'dokumenttype',
             'titel'],
            validate._get_mandatory('dokument', 'egenskaber')
        )

    def test_loghaendelse(self):
        self.assertEqual([],
                         validate._get_mandatory('loghaendelse', 'egenskaber'))


class TestGenerateJSONSchema(unittest.TestCase):
    maxDiff = None

    def setUp(self):
        self.relation_nul_til_mange = {
            'type': 'array',
            'items': {
                'oneOf': [
                    {
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
                    {
                        'type': 'object',
                        'properties': {
                            'urn': {
                                'type': 'string',
                            },
                            'virkning': {'$ref': '#/definitions/virkning'},
                            'objekttype': {'type': 'string'}
                        },
                        'required': ['urn', 'virkning'],
                        'additionalProperties': False
                    }
                ]
            },
        }

        self.relation_nul_til_en = copy.deepcopy(self.relation_nul_til_mange)
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

    def test_relationer_aktivitet(self):
        aktoerattr = {
            'aktoerattr': {
                'type': 'object',
                'properties': {
                    'accepteret': {'type': 'string'},
                    'obligatorisk': {'type': 'string'},
                    'repraesentation_uuid': {
                        'type': 'string',
                        'pattern': '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-'
                                   '[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-'
                                   '[a-fA-F0-9]{12}$'
                    },
                },
                'required': ['accepteret', 'obligatorisk',
                             'repraesentation_uuid'],
                'additionalProperties': False
            }
        }
        self.relation_nul_til_en['items']['oneOf'][0]['properties'].update(
            copy.deepcopy(aktoerattr))
        self.relation_nul_til_en['items']['oneOf'][1]['properties'].update(
            copy.deepcopy(aktoerattr))
        aktoerattr['indeks'] = {'type': 'integer'}
        self.relation_nul_til_mange['items']['oneOf'][0]['properties'].update(
            aktoerattr)
        self.relation_nul_til_mange['items']['oneOf'][1]['properties'].update(
            aktoerattr)

        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'aktivitetstype': self.relation_nul_til_en,
                    'emne': self.relation_nul_til_en,
                    'foelsomhedklasse': self.relation_nul_til_en,
                    'ansvarligklasse': self.relation_nul_til_en,
                    'rekvirentklasse': self.relation_nul_til_en,
                    'ansvarlig': self.relation_nul_til_en,
                    'tilhoerer': self.relation_nul_til_en,
                    'udfoererklasse': self.relation_nul_til_mange,
                    'deltagerklasse': self.relation_nul_til_mange,
                    'objektklasse': self.relation_nul_til_mange,
                    'resultatklasse': self.relation_nul_til_mange,
                    'grundlagklasse': self.relation_nul_til_mange,
                    'facilitetklasse': self.relation_nul_til_mange,
                    'adresse': self.relation_nul_til_mange,
                    'geoobjekt': self.relation_nul_til_mange,
                    'position': self.relation_nul_til_mange,
                    'facilitet': self.relation_nul_til_mange,
                    'lokale': self.relation_nul_til_mange,
                    'aktivitetdokument': self.relation_nul_til_mange,
                    'aktivitetgrundlag': self.relation_nul_til_mange,
                    'aktivitetresultat': self.relation_nul_til_mange,
                    'udfoerer': self.relation_nul_til_mange,
                    'deltager': self.relation_nul_til_mange,
                },
                'additionalProperties': False
            },
            validate._generate_relationer('aktivitet')
        )

    def test_relationer_indsats(self):
        self.relation_nul_til_mange['items']['oneOf'][0]['properties'][
            'indeks'] = {'type': 'integer'}
        self.relation_nul_til_mange['items']['oneOf'][1]['properties'][
            'indeks'] = {'type': 'integer'}
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'indsatsmodtager': self.relation_nul_til_en,
                    'indsatstype': self.relation_nul_til_en,
                    'indsatskvalitet': self.relation_nul_til_mange,
                    'indsatsaktoer': self.relation_nul_til_mange,
                    'samtykke': self.relation_nul_til_mange,
                    'indsatssag': self.relation_nul_til_mange,
                    'indsatsdokument': self.relation_nul_til_mange,
                },
                'additionalProperties': False
            },
            validate._generate_relationer('indsats')
        )

    def test_relationer_tilstand(self):
        self.relation_nul_til_mange['items']['oneOf'][0]['properties'][
            'indeks'] = {'type': 'integer'}
        self.relation_nul_til_mange['items']['oneOf'][1]['properties'][
            'indeks'] = {'type': 'integer'}
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'tilstandsobjekt': self.relation_nul_til_en,
                    'tilstandstype': self.relation_nul_til_en,
                    'begrundelse': self.relation_nul_til_mange,
                    'tilstandskvalitet': self.relation_nul_til_mange,
                    'tilstandsvurdering': self.relation_nul_til_mange,
                    'tilstandsaktoer': self.relation_nul_til_mange,
                    'tilstandsudstyr': self.relation_nul_til_mange,
                    'samtykke': self.relation_nul_til_mange,
                    'tilstandsdokument': self.relation_nul_til_mange,
                    'tilstandsvaerdi': {
                        'type': 'array',
                        'items': {
                            'type': 'object',
                            'properties': {
                                'indeks': {'type': 'integer'},
                                'tilstandsvaerdiattr': {
                                    'type': 'object',
                                    'properties': {
                                        'forventet': {'type': 'boolean'},
                                        'nominelvaerdi': {'type': 'string'}
                                    },
                                    'required': ['forventet', 'nominelvaerdi'],
                                    'additionalProperties': False
                                },
                                'virkning': {'$ref': '#/definitions/virkning'},
                                'objekttype': {'type': 'string'}
                            },
                            'required': ['virkning'],
                            'additionalProperties': False
                        },
                    }
                },
                'additionalProperties': False
            },
            validate._generate_relationer('tilstand')
        )

    def test_relationer_sag(self):
        self.relation_nul_til_mange['items']['oneOf'][0]['properties'][
            'indeks'] = {'type': 'integer'}
        self.relation_nul_til_mange['items']['oneOf'][1]['properties'][
            'indeks'] = {'type': 'integer'}
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'behandlingarkiv': self.relation_nul_til_en,
                    'afleveringsarkiv': self.relation_nul_til_en,
                    'primaerklasse': self.relation_nul_til_en,
                    'opgaveklasse': self.relation_nul_til_en,
                    'handlingsklasse': self.relation_nul_til_en,
                    'kontoklasse': self.relation_nul_til_en,
                    'sikkerhedsklasse': self.relation_nul_til_en,
                    'foelsomhedsklasse': self.relation_nul_til_en,
                    'indsatsklasse': self.relation_nul_til_en,
                    'ydelsesklasse': self.relation_nul_til_en,
                    'ejer': self.relation_nul_til_en,
                    'ansvarlig': self.relation_nul_til_en,
                    'primaerbehandler': self.relation_nul_til_en,
                    'udlaanttil': self.relation_nul_til_en,
                    'primaerpart': self.relation_nul_til_en,
                    'ydelsesmodtager': self.relation_nul_til_en,
                    'oversag': self.relation_nul_til_en,
                    'praecedens': self.relation_nul_til_en,
                    'afgiftsobjekt': self.relation_nul_til_en,
                    'ejendomsskat': self.relation_nul_til_en,
                    'andetarkiv': self.relation_nul_til_mange,
                    'andrebehandlere': self.relation_nul_til_mange,
                    'sekundaerpart': self.relation_nul_til_mange,
                    'andresager': self.relation_nul_til_mange,
                    'byggeri': self.relation_nul_til_mange,
                    'fredning': self.relation_nul_til_mange,
                    'journalpost': {
                        'type': 'array',
                        'items': {
                            'oneOf': [
                                {
                                    'type': 'object',
                                    'properties': {
                                        'indeks': {'type': 'integer'},
                                        'journaldokument': {
                                            'type': 'object',
                                            'properties': {
                                                'dokumenttitel': {
                                                    'type': 'string'},
                                                'offentlighedundtaget': {
                                                    '$ref': '#/definitions/'
                                                            'offentlighed'
                                                            'undtaget'
                                                }
                                            },
                                            'required': [
                                                'dokumenttitel',
                                                'offentlighedundtaget'
                                            ],
                                            'additionalProperties': False,
                                        },
                                        'journalnotat': {
                                            'type': 'object',
                                            'properties': {
                                                'format': {'type': 'string'},
                                                'notat': {'type': 'string'},
                                                'titel': {'type': 'string'}
                                            },
                                            'required': ['titel', 'notat',
                                                         'format'],
                                            'additionalProperties': False,
                                        },
                                        'journalpostkode': {
                                            'type': 'string',
                                            'enum': ['journalnotat',
                                                     'vedlagtdokument'],
                                        },
                                        'uuid': {
                                            'type': 'string',
                                            'pattern': '^[a-fA-F0-9]{8}-'
                                                       '[a-fA-F0-9]{4}'
                                                       '-[a-fA-F0-9]{4}-'
                                                       '[a-fA-F0-9]{4}'
                                                       '-[a-fA-F0-9]{12}$',
                                        },
                                        'virkning': {
                                            '$ref': '#/definitions/virkning'},
                                        'objekttype': {'type': 'string'}
                                    },
                                    'required': ['uuid', 'virkning',
                                                 'journalpostkode'],
                                    'additionalProperties': False
                                },
                                {
                                    'type': 'object',
                                    'properties': {
                                        'indeks': {'type': 'integer'},
                                        'journaldokument': {
                                            'type': 'object',
                                            'properties': {
                                                'dokumenttitel': {
                                                    'type': 'string'},
                                                'offentlighedundtaget': {
                                                    '$ref': '#/definitions/'
                                                            'offentlighed'
                                                            'undtaget'
                                                }
                                            },
                                            'required': [
                                                'dokumenttitel',
                                                'offentlighedundtaget'
                                            ],
                                            'additionalProperties': False,
                                        },
                                        'journalnotat': {
                                            'type': 'object',
                                            'properties': {
                                                'format': {'type': 'string'},
                                                'notat': {'type': 'string'},
                                                'titel': {'type': 'string'}
                                            },
                                            'required': ['titel', 'notat',
                                                         'format'],
                                            'additionalProperties': False,
                                        },
                                        'journalpostkode': {
                                            'type': 'string',
                                            'enum': ['journalnotat',
                                                     'vedlagtdokument'],
                                        },
                                        'urn': {
                                            'type': 'string',
                                        },
                                        'virkning': {
                                            '$ref': '#/definitions/virkning'},
                                        'objekttype': {'type': 'string'}
                                    },
                                    'required': ['urn', 'virkning',
                                                 'journalpostkode'],
                                    'additionalProperties': False
                                }
                            ]
                        },
                    }
                },
                'additionalProperties': False
            },
            validate._generate_relationer('sag')
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

    def test_attributter_itsystem(self):
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'itsystemegenskaber': {
                        'type': 'array',
                        'items': {
                            'type': 'object',
                            'properties': {
                                'brugervendtnoegle': {'type': 'string'},
                                'itsystemnavn': {'type': 'string'},
                                'itsystemtype': {'type': 'string'},
                                'konfigurationreference': {
                                    'type': 'array',
                                    'items': {'type': 'string'}
                                },
                                'virkning': {'$ref': '#/definitions/virkning'}
                            },
                            'required': ['brugervendtnoegle', 'virkning'],
                            'additionalProperties': False
                        }
                    }
                },
                'required': ['itsystemegenskaber'],
                'additionalProperties': False
            },
            validate._generate_attributter('itsystem')
        )

    def test_attributter_sag(self):
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'sagegenskaber': {
                        'type': 'array',
                        'items': {
                            'type': 'object',
                            'properties': {
                                'brugervendtnoegle': {'type': 'string'},
                                'sagsnummer': {'type': 'string'},
                                'titel': {'type': 'string'},
                                'beskrivelse': {'type': 'string'},
                                'hjemmel': {'type': 'string'},
                                'offentlighedundtaget': {
                                    '$ref': '#/definitions/'
                                            'offentlighedundtaget'
                                },
                                'principiel': {'type': 'boolean'},
                                'kassationskode': {'type': 'string'},
                                'afleveret': {'type': 'boolean'},
                                'virkning': {'$ref': '#/definitions/virkning'}
                            },
                            'required': ['beskrivelse', 'brugervendtnoegle',
                                         'kassationskode', 'sagsnummer',
                                         'titel', 'virkning'],
                            'additionalProperties': False
                        }
                    }
                },
                'required': ['sagegenskaber'],
                'additionalProperties': False
            },
            validate._generate_attributter('sag')
        )

    def test_attributter_dokument(self):
        self.assertEqual(
            {
                'type': 'object',
                'properties': {
                    'dokumentegenskaber': {
                        'type': 'array',
                        'items': {
                            'type': 'object',
                            'properties': {
                                'brugervendtnoegle': {'type': 'string'},
                                'beskrivelse': {'type': 'string'},
                                'brevdato': {'type': 'string'},
                                'dokumenttype': {'type': 'string'},
                                'kassationskode': {'type': 'string'},
                                'major': {'type': 'integer'},
                                'minor': {'type': 'integer'},
                                'offentlighedundtaget': {
                                    '$ref': '#/definitions/'
                                            'offentlighedundtaget'
                                },
                                'titel': {'type': 'string'},
                                'virkning': {'$ref': '#/definitions/virkning'}
                            },
                            'required': ['beskrivelse', 'brevdato',
                                         'brugervendtnoegle', 'dokumenttype',
                                         'titel', 'virkning'],
                            'additionalProperties': False
                        }
                    }
                },
                'required': ['dokumentegenskaber'],
                'additionalProperties': False
            },
            validate._generate_attributter('dokument')
        )

    def test_index_allowed_in_relations_for_aktivitet(self):
        relationer = validate._generate_relationer('aktivitet')
        self.assertEqual(
            {'type': 'integer'},
            relationer['properties']['deltager']['items']['oneOf'][0][
                'properties']['indeks'])
        self.assertEqual(
            {'type': 'integer'},
            relationer['properties']['deltager']['items']['oneOf'][1][
                'properties']['indeks'])

    def test_index_allowed_in_relations_for_sag(self):
        relationer = validate._generate_relationer('sag')
        self.assertEqual(
            {'type': 'integer'},
            relationer['properties']['andrebehandlere']['items']['oneOf'][0][
                'properties']['indeks'])
        self.assertEqual(
            {'type': 'integer'},
            relationer['properties']['andrebehandlere']['items']['oneOf'][1][
                'properties']['indeks'])

    def test_index_allowed_in_relations_for_tilstand(self):
        relationer = validate._generate_relationer('tilstand')
        self.assertEqual(
            {'type': 'integer'},
            relationer['properties']['samtykke']['items']['oneOf'][0][
                'properties']['indeks'])
        self.assertEqual(
            {'type': 'integer'},
            relationer['properties']['samtykke']['items']['oneOf'][1][
                'properties']['indeks'])

    def test_index_allowed_in_relations_for_indsats(self):
        relationer = validate._generate_relationer('indsats')
        self.assertEqual(
            {'type': 'integer'},
            relationer['properties']['samtykke']['items']['oneOf'][0][
                'properties']['indeks'])
        self.assertEqual(
            {'type': 'integer'},
            relationer['properties']['samtykke']['items']['oneOf'][1][
                'properties']['indeks'])

    def test_index_not_allowed_for_non_special_nul_til_mange_relations(self):
        relationer = validate._generate_relationer('organisation')
        self.assertFalse(
            'indeks' in relationer['properties']['ansatte']['items'][
                'oneOf'][0]['properties'])
        self.assertFalse(
            'indeks' in relationer['properties']['ansatte']['items'][
                'oneOf'][1]['properties'])

    def test_object_type_is_organisation(self):
        quasi_org = {
            'attributter': {
                "organisationegenskaber": []
            }
        }
        self.assertEqual('organisation',
                         validate.get_lora_object_type(quasi_org))

    def test_object_type_is_organisationenhed(self):
        quasi_org_enhed = {
            'attributter': {
                "organisationenhedegenskaber": []
            }
        }
        self.assertEqual('organisationenhed',
                         validate.get_lora_object_type(quasi_org_enhed))

    def test_raise_exception_if_obj_egenskaber_not_set(self):
        quasi_org = {
            'attributter': {
                "invalid-egenskaber": []
            }
        }
        with self.assertRaises(jsonschema.exceptions.ValidationError):
            validate.get_lora_object_type(quasi_org)

    def test_raise_exception_if_attributter_not_set(self):
        quasi_org = {
            'invalid-attributter': {
                "organisationegenskaber": []
            }
        }
        with self.assertRaises(jsonschema.exceptions.ValidationError):
            validate.get_lora_object_type(quasi_org)

    def test_create_facet_request_valid(self):
        req = self._json_to_dict('facet_opret.json')
        obj = validate.get_lora_object_type(req)
        jsonschema.validate(req, validate.SCHEMA[obj])

    def test_create_facet_request_invalid(self):
        req = self._json_to_dict('facet_opret.json')

        # Change JSON key to invalid value
        req['attributter']['facetegenskaber'][0]['xyz_supplement'] = \
            req['attributter']['facetegenskaber'][0].pop('supplement')

        with self.assertRaises(jsonschema.exceptions.ValidationError):
            obj = validate.get_lora_object_type(req)
            jsonschema.validate(req, validate.SCHEMA[obj])

    def test_create_bruger_request_valid(self):
        req = self._json_to_dict('bruger_opret.json')
        obj = validate.get_lora_object_type(req)
        jsonschema.validate(req, validate.SCHEMA[obj])

    def test_create_klassifikation_request_valid(self):
        req = self._json_to_dict('klassifikation_opret.json')
        obj = validate.get_lora_object_type(req)
        jsonschema.validate(req, validate.SCHEMA[obj])

    def test_create_klasse_request_valid(self):
        req = self._json_to_dict('klasse_opret.json')
        obj = validate.get_lora_object_type(req)
        jsonschema.validate(req, validate.SCHEMA[obj])

    def test_create_aktivitet_request_valid(self):
        req = self._json_to_dict('aktivitet_opret.json')
        obj = validate.get_lora_object_type(req)
        jsonschema.validate(req, validate.SCHEMA[obj])

    def test_create_tilstand_request_valid(self):
        req = self._json_to_dict('tilstand_opret.json')
        obj = validate.get_lora_object_type(req)
        jsonschema.validate(req, validate.SCHEMA[obj])

    def test_create_indsats_request_valid(self):
        req = self._json_to_dict('indsats_opret.json')
        obj = validate.get_lora_object_type(req)
        jsonschema.validate(req, validate.SCHEMA[obj])

    def test_create_itsystem_request_valid(self):
        req = self._json_to_dict('itsystem_opret.json')
        obj = validate.get_lora_object_type(req)
        jsonschema.validate(req, validate.SCHEMA[obj])

    def test_create_loghaendelse_request_valid(self):
        req = self._json_to_dict('loghaendelse_opret.json')
        obj = validate.get_lora_object_type(req)
        jsonschema.validate(req, validate.SCHEMA[obj])

    def test_create_sag_request_valid(self):
        req = self._json_to_dict('sag_opret.json')
        obj = validate.get_lora_object_type(req)
        jsonschema.validate(req, validate.SCHEMA[obj])

    @unittest.skip('Due to an inconsistency between the way LoRa handles '
                   '"DokumentVariantEgenskaber" and the specs')
    def test_create_dokument_request_valid(self):
        req = self._json_to_dict('dokument_opret.json')
        obj = validate.get_lora_object_type(req)
        jsonschema.validate(req, validate.SCHEMA[obj])


class TestFacetSystematically(unittest.TestCase):
    def setUp(self):
        self.standard_virkning1 = {
            "from": "2000-01-01 12:00:00+01",
            "from_included": True,
            "to": "2020-01-01 12:00:00+01",
            "to_included": False
        }
        self.standard_virkning2 = {
            "from": "2020-01-01 12:00:00+01",
            "from_included": True,
            "to": "2030-01-01 12:00:00+01",
            "to_included": False
        }
        self.reference = {
            'uuid': '00000000-0000-0000-0000-000000000000',
            'virkning': self.standard_virkning1
        }
        self.facet = {
            'attributter': {
                'facetegenskaber': [
                    {
                        'brugervendtnoegle': 'bvn1',
                        'virkning': self.standard_virkning1
                    }
                ]
            },
            'tilstande': {
                'facetpubliceret': [
                    {
                        'publiceret': 'Publiceret',
                        'virkning': self.standard_virkning1
                    }
                ]
            }
        }

    def assertValidationError(self):
        with self.assertRaises(jsonschema.exceptions.ValidationError):
            jsonschema.validate(self.facet, validate.SCHEMA['facet'])

    def test_valid_equivalence_classes1(self):
        """
        Equivalence classes covered: [44][48][80][53][77][79][83][86][89][92]
        [61][63][67][68][101][102][108][109][111]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        jsonschema.validate(self.facet, validate.SCHEMA['facet'])

    def test_valid_equivalence_classes2(self):
        """
        Equivalence classes covered: [45][50][81][84][87][90][93][55][62]
        [64][69]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['note'] = 'This is a note'
        egenskaber = self.facet['attributter']['facetegenskaber'][0]
        egenskaber['beskrivelse'] = 'xyz'
        egenskaber['plan'] = 'xyz'
        egenskaber['opbygning'] = 'xyz'
        egenskaber['ophavsret'] = 'xyz'
        egenskaber['supplement'] = 'xyz'
        egenskaber['retskilde'] = 'xyz'

        self.facet['attributter']['facetegenskaber'].append(
            {
                'brugervendtnoegle': 'bvn2',
                'virkning': self.standard_virkning2
            }
        )

        self.facet['tilstande']['facetpubliceret'].append(
            {
                'publiceret': 'IkkePubliceret',
                'virkning': self.standard_virkning2
            }
        )

        self.facet['relationer'] = {}

        jsonschema.validate(self.facet, validate.SCHEMA['facet'])

    def test_valid_equivalence_classes3(self):
        """
        Equivalence classes covered: [70][72]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['relationer'] = {
            'ansvarlig': []
        }

        jsonschema.validate(self.facet, validate.SCHEMA['facet'])

    def test_valid_equivalence_classes4(self):
        """
        Equivalence classes covered: [71][74][76][112]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        urn = {
            'urn': 'This is an URN',
            'virkning': self.standard_virkning1
        }
        self.facet['relationer'] = {
            'ansvarlig': [self.reference],
            'ejer': [urn],
            'facettilhoerer': [self.reference],
            'redaktoerer': [self.reference, urn]
        }

        jsonschema.validate(self.facet, validate.SCHEMA['facet'])

    def test_note_not_string(self):
        """
        Equivalence classes covered: [43]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['note'] = ['This is not a string']
        self.assertValidationError()

    def test_bvn_missing(self):
        """
        Equivalence classes covered: [46]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet['attributter']['facetegenskaber'][0][
            'brugervendtnoegle']
        self.assertValidationError()

    def test_bvn_not_string(self):
        """
        Equivalence classes covered: [47]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0][
            'brugervendtnoegle'] = {
            'dummy': 'This is not a string'
        }
        self.assertValidationError()

    def test_beskrivelse_not_string(self):
        """
        Equivalence classes covered: [49]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0]['beskrivelse'] = {
            'dummy': 'This is not a string'
        }
        self.assertValidationError()

    def test_plan_not_string(self):
        """
        Equivalence classes covered: [78]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0]['plan'] = {
            'dummy': 'This is not a string'
        }
        self.assertValidationError()

    def test_opbygning_not_string(self):
        """
        Equivalence classes covered: [82]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0]['opbygning'] = {
            'dummy': 'This is not a string'
        }
        self.assertValidationError()

    def test_ophavsret_not_string(self):
        """
        Equivalence classes covered: [85]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0]['ophavsret'] = {
            'dummy': 'This is not a string'
        }
        self.assertValidationError()

    def test_supplement_not_string(self):
        """
        Equivalence classes covered: [88]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0]['supplement'] = {
            'dummy': 'This is not a string'
        }
        self.assertValidationError()

    def test_retskilde_not_string(self):
        """
        Equivalence classes covered: [91]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0]['retskilde'] = {
            'dummy': 'This is not a string'
        }
        self.assertValidationError()

    def test_virkning_missing_attributter(self):
        """
        Equivalence classes covered: [51]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet['attributter']['facetegenskaber'][0]['virkning']
        self.assertValidationError()

    def test_egenskaber_missing(self):
        """
        Equivalence classes covered: [54]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet['attributter']['facetegenskaber']
        self.assertValidationError()

    def test_unknown_key_in_facetegenskaber(self):
        """
        Equivalence classes covered: [94]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0]['unknown'] = 'xyz'
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
        del self.facet['attributter']
        self.assertValidationError()

    def test_tilstande_missing(self):
        """
        Equivalence classes covered: [58]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet['tilstande']
        self.assertValidationError()

    def test_facetpubliceret_missing(self):
        """
        Equivalence classes covered: [60]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet['tilstande']['facetpubliceret']
        self.assertValidationError()

    def test_publiceret_not_valid_enum(self):
        """
        Equivalence classes covered: [61]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['tilstande']['facetpubliceret'][0]['publiceret'] = 'invalid'
        self.assertValidationError()

    def test_publiceret_missing(self):
        """
        Equivalence classes covered: [62]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet['tilstande']['facetpubliceret'][0]['publiceret']
        self.assertValidationError()

    def test_virkning_malformed_tilstande(self):
        """
        Equivalence classes covered: [66]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet['tilstande']['facetpubliceret'][0]['virkning']['from']
        self.assertValidationError()

    def test_unknown_key_in_facetpubliceret(self):
        """
        Equivalence classes covered: [95]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['tilstande']['facetpubliceret'][0]['unknown'] = 'xyz'
        self.assertValidationError()

    def test_two_references_in_nul_til_en_relation(self):
        """
        Equivalence classes covered: [96]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['relationer'] = {
            'ansvarlig': [self.reference, self.reference],
        }
        self.assertValidationError()

    def test_reference_not_an_uuid(self):
        """
        Equivalence classes covered: [73]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.reference['uuid'] = 'This is not an UUID'
        self.facet['relationer'] = {
            'ansvarlig': [self.reference],
        }
        self.assertValidationError()

    def test_unknown_relation_name(self):
        """
        Equivalence classes covered: [75]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['relationer'] = {
            'unknown': [self.reference],
        }
        self.assertValidationError()

    def test_virkning_aktoer_and_note_ok(self):
        """
        Equivalence classes covered: [104][106][110]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0]['virkning'].update(
            {
                'aktoerref': '00000000-0000-0000-0000-000000000000',
                'aktoertypekode': 'type',
                'notetekst': 'This is a note'
            }
        )
        jsonschema.validate(self.facet, validate.SCHEMA['facet'])

    def test_virkning_from_missing(self):
        """
        Equivalence classes covered: [52][97]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet['attributter']['facetegenskaber'][0]['virkning']['from']
        self.assertValidationError()

    def test_virkning_to_missing(self):
        """
        Equivalence classes covered: [99]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        del self.facet['attributter']['facetegenskaber'][0]['virkning']['to']
        self.assertValidationError()

    def test_virkning_from_not_string(self):
        """
        Equivalence classes covered: [98]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0]['virkning']['from'] = {
            'key': 'This is not a string'
        }
        self.assertValidationError()

    def test_virkning_to_not_string(self):
        """
        Equivalence classes covered: [100]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0]['virkning']['to'] = {
            'key': 'This is not a string'
        }
        self.assertValidationError()

    def test_virkning_aktoerref_not_uuid(self):
        """
        Equivalence classes covered: [103]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0]['virkning'][
            'aktoerref'] = 'This is not an UUID'
        self.assertValidationError()

    def test_virkning_aktoertype_not_string(self):
        """
        Equivalence classes covered: [105]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0]['virkning'][
            'aktoertypekode'] = {
            'key': 'This is not a string'
        }
        self.assertValidationError()

    def test_virkning_notetekst_not_string(self):
        """
        Equivalence classes covered: [107]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """
        self.facet['attributter']['facetegenskaber'][0]['virkning'][
            'notetekst'] = {
            'key': 'This is not a string'
        }
        self.assertValidationError()
