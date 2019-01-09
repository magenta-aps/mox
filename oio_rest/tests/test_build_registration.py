# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import unittest

from mock import MagicMock, patch

import oio_rest.utils.build_registration as br


class TestBuildRegistration(unittest.TestCase):
    def test_is_urn_returns_true_when_string_begins_with_urn(self):
        urn1 = "urn:thisisaurn"
        self.assertTrue(br.is_urn(urn1))

        urn2 = "URN:thisisaurn"
        self.assertTrue(br.is_urn(urn2))

    def test_is_urn_returns_false_when_string_does_not_begin_with_urn(self):
        urn = "this is not a urn"
        self.assertFalse(br.is_urn(urn))

    def test_is_uuid_returns_true_when_string_is_uuid(self):
        uuid = "c97e1dee-1477-4dd4-a2e6-0bfc6b6b04da"
        self.assertTrue(br.is_uuid(uuid))

    def test_is_uuid_returns_false_when_string_is_not_uuid(self):
        uuid = "notuuid"
        self.assertFalse(br.is_uuid(uuid))

    def test_escape_underscores(self):
        # Arrange
        value = 'a_string_with_underscores'

        expected_result = 'a\_string\_with\_underscores'
        # Act
        actual_result = br.escape_underscores(value)
        # Assert
        self.assertEqual(expected_result, actual_result)

    def test_escape_underscores_if_none(self):
        # Arrange
        value = None

        # Act
        actual_result = br.escape_underscores(value)
        # Assert
        self.assertEqual(value, actual_result)

    def test_build_relation_builds_correct_relation_with_uuid_value(self):
        virkning = "VIRKNING"
        objekttype = "OBJEKTTYPE"

        value = "e16f42c5-cd64-411d-827a-15c9198e932d"

        expected_relation = {
            'virkning': virkning,
            'objekttype': objekttype,
            'uuid': value
        }

        actual_relation = br.build_relation(value=value, virkning=virkning,
                                            objekttype=objekttype)

        self.assertEqual(expected_relation, actual_relation)

    def test_build_relation_builds_correct_relation_with_urn_value(self):
        virkning = "VIRKNING"
        objekttype = "OBJEKTTYPE"

        value = "urn:urnvalue"

        expected_relation = {
            'virkning': virkning,
            'objekttype': objekttype,
            'urn': value
        }

        actual_relation = br.build_relation(value=value, virkning=virkning,
                                            objekttype=objekttype)

        self.assertEqual(expected_relation, actual_relation)

    def test_build_relation_raises_ValueError_on_non_uuid_or_non_urn_value(
            self):
        value = "not urn or uuid"

        with self.assertRaises(ValueError):
            br.build_relation(value)

    def test_split_param_splits_on_colon(self):
        # Arrange
        value = 'first:second'
        expected_result = ('first', 'second')

        # Act
        actual_result = br.split_param(value)

        # Assert
        self.assertEqual(expected_result, actual_result)

    def test_split_param_handles_valueerror(self):
        # Arrange
        value = 'nosplit'
        expected_result = ('nosplit', None)

        # Act
        actual_result = br.split_param(value)

        # Assert
        self.assertEqual(expected_result, actual_result)

    def test_to_lower_param_lowers_first_item(self):
        # Arrange
        value = 'FIRST:second'
        expected_result = 'first:second'

        # Act
        actual_result = br.to_lower_param(value)

        # Assert
        self.assertEqual(expected_result, actual_result)

    def test_to_lower_param_handles_value_error(self):
        # Arrange
        value = 'Nosplit'
        expected_result = 'nosplit'

        # Act
        actual_result = br.to_lower_param(value)

        # Assert
        self.assertEqual(expected_result, actual_result)

    def test_dict_from_dot_notation(self):
        # Arrange
        notation = 'a.b.c'
        value = 1
        expected_result = {'a': {'b': {'c': 1}}}

        # Act
        actual_result = br.dict_from_dot_notation(notation, value)

        # Assert
        self.assertEqual(expected_result, actual_result)

    def test_add_journal_post_relation_fields_journalpostkode(self):
        # Arrange
        param = 'journalpostkode'
        values = ['value_with_underscores', 'value']
        relation = {'testkey': 'testvalue'}

        expected_result = {
            'testkey': 'testvalue',
            'journalpost': [
                {
                    'virkning': None,
                    'journalpostkode': 'value_with_underscores'
                },
                {
                    'virkning': None,
                    'journalpostkode': 'value'
                },
            ]
        }

        # Act
        br.add_journal_post_relation_fields(param, values, relation)

        # Assert
        self.assertEqual(expected_result, relation)

    def test_add_journal_post_relation_fields_non_journalpostkode(self):
        # Arrange
        param = 'journaldokument.dokumenttitel'
        values = ['value_with_underscores', 'value']
        relation = {'testkey': 'testvalue'}

        expected_result = {
            'testkey': 'testvalue',
            'journalpost': [
                {
                    'journaldokument': {
                        'dokumenttitel': 'value\_with\_underscores'
                    },
                    'virkning': None,
                },
                {
                    'journaldokument': {
                        'dokumenttitel': 'value'
                    },
                    'virkning': None,
                },
            ]
        }

        # Act
        br.add_journal_post_relation_fields(param, values, relation)

        # Assert
        self.assertEqual(expected_result, relation)

    def test_add_journal_post_relation_fields_unknown_param(self):
        # Arrange
        param = 'testparam'
        values = ['value_with_underscores', 'value']
        relation = {'testkey': 'testvalue'}

        expected_result = {
            'testkey': 'testvalue'
        }

        # Act
        br.add_journal_post_relation_fields(param, values, relation)

        # Assert
        self.assertEqual(expected_result, relation)

    @patch('oio_rest.utils.build_registration.build_registration')
    def test_restriction_to_registration(self, mock_br):
        # type: (MagicMock) -> None
        # Arrange
        classname = 'class'
        restriction = (
            {
                'attribute1': 'val1',
                'attribute2': 'val2',
            },
            {
                'state1': 'val3',
                'state2': 'val4',
            },
            {
                'relation1': 'val5',
                'relation2': 'val6',
            }
        )

        expected_list_args = {
            'attribute1': ['val1'],
            'attribute2': ['val2'],
            'state1': ['val3'],
            'state2': ['val4'],
            'relation1': ['val5'],
            'relation2': ['val6'],
        }

        # Act
        br.restriction_to_registration(classname, restriction)

        # Assert
        actual_class_name = mock_br.call_args[0][0]
        actual_list_args = mock_br.call_args[0][1]
        self.assertEqual(classname, actual_class_name)
        self.assertEqual(expected_list_args, actual_list_args)

    @patch('oio_rest.utils.build_registration.get_relation_names',
           new=MagicMock())
    @patch('oio_rest.utils.build_registration.get_state_names',
           new=MagicMock())
    @patch('oio_rest.utils.build_registration.get_attribute_fields')
    @patch('oio_rest.utils.build_registration.get_attribute_names')
    def test_build_registration_attributes(self,
                                           mock_get_attribute_names,
                                           mock_get_attribute_fields):
        # type: (MagicMock, MagicMock) -> None
        # Arrange
        mock_get_attribute_names.return_value = ['attributename']
        mock_get_attribute_fields.return_value = ['arg1']

        classname = 'class'
        list_args = {
            'arg1': ['val1'],
            'arg2': ['val2'],
        }
        expected_result = {
            'attributes': {
                'attributename': [
                    {
                        'virkning': None,
                        'arg1': 'val1'
                    }
                ]
            },
            'states': {},
            'relations': {}
        }

        # Act
        actual_result = br.build_registration(classname, list_args)

        # Assert
        self.assertEqual(expected_result, actual_result)

    @patch('oio_rest.utils.build_registration.get_relation_names',
           new=MagicMock())
    @patch('oio_rest.utils.build_registration.get_state_names')
    @patch('oio_rest.utils.build_registration.get_attribute_fields',
           new=MagicMock())
    @patch('oio_rest.utils.build_registration.get_attribute_names',
           new=MagicMock())
    def test_build_registration_states(self,
                                       mock_get_state_names):
        # type: (MagicMock, MagicMock) -> None
        # Arrange
        mock_get_state_names.return_value = ['statename']

        classname = 'class'
        list_args = {
            'statename': ['val1', 'val2'],
            'whatever': ['whatever'],
        }

        expected_result = {
            'states': {
                'statename': [
                    {
                        'virkning': None,
                        'statename': 'val1'
                    },
                    {
                        'virkning': None,
                        'statename': 'val2'
                    }
                ]
            },
            'attributes': {},
            'relations': {}
        }

        # Act
        actual_result = br.build_registration(classname, list_args)

        # Assert
        self.assertEqual(expected_result, actual_result)

    @patch('oio_rest.utils.build_registration.get_relation_names')
    @patch('oio_rest.utils.build_registration.get_state_names',
           new=MagicMock())
    @patch('oio_rest.utils.build_registration.get_attribute_fields',
           new=MagicMock())
    @patch('oio_rest.utils.build_registration.get_attribute_names',
           new=MagicMock())
    def test_build_registration_relations(self, mock_get_relation_names):
        # type: (MagicMock) -> None
        # Arrange
        mock_get_relation_names.return_value = ['relationname']

        classname = 'class'
        list_args = {
            'arg1': ['val1'],
            'relationname:objtype': ['urn:123'],
        }
        expected_result = {
            'relations': {
                'relationname': [
                    {
                        'objekttype': 'objtype',
                        'urn': 'urn:123',
                        'virkning': None
                    }
                ]
            },
            'states': {},
            'attributes': {}
        }

        # Act
        actual_result = br.build_registration(classname, list_args)

        # Assert
        self.assertEqual(expected_result, actual_result)

    @patch('oio_rest.utils.build_registration.'
           'get_document_part_relation_names')
    @patch('oio_rest.utils.build_registration.'
           'DokumentDelEgenskaberType.get_fields')
    @patch('oio_rest.utils.build_registration.'
           'DokumentVariantEgenskaberType.get_fields')
    def test_build_registration_dokument(self, mock_dvet_get_fields,
                                         mock_ddet_get_fields, mock_get_dprn):
        # Arrange
        mock_dvet_get_fields.return_value = ['testvariantegenskab']
        mock_ddet_get_fields.return_value = ['testdelegenskab']
        mock_get_dprn.return_value = ['testdelrelnavn']

        list_args = {
            'varianttekst': ['testtekst'],
            'deltekst': ['testdeltekst'],
            'testvariantegenskab': ['val1', 'val2'],
            'testdelegenskab': ['val3', 'val4'],
            'testdelrelnavn:objtype': ['urn:1234'],
        }

        expected_result = {
            "variants": [
                {
                    "dele": [
                        {
                            "egenskaber": [
                                {
                                    "virkning": None,
                                    "testdelegenskab": "val3"
                                },
                                {
                                    "virkning": None,
                                    "testdelegenskab": "val4"
                                }
                            ],
                            "relationer": {
                                "testdelrelnavn": [
                                    {
                                        "virkning": None,
                                        "urn": "urn:1234",
                                        "objekttype": "objtype"
                                    }
                                ]
                            },
                            "deltekst": "testdeltekst"
                        }
                    ],
                    "egenskaber": [
                        {
                            "virkning": None,
                            "testvariantegenskab": "val1"
                        },
                        {
                            "virkning": None,
                            "testvariantegenskab": "val2"
                        }
                    ],
                    "varianttekst": "testtekst"
                }
            ],
            "states": {
                "fremdrift": []
            },
            "attributes": {},
            "relations": {}
        }

        # Act
        actual_result = br.build_registration('Dokument', list_args)

        # Assert
        self.assertEqual(expected_result, actual_result)
