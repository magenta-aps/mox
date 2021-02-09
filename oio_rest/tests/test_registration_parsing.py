# SPDX-FileCopyrightText: 2021- Magenta ApS
# SPDX-License-Identifier: MPL-2.0
from datetime import datetime
from unittest import TestCase

from oio_rest.db.db_structure import REAL_DB_STRUCTURE
from oio_rest.db.quick_query.registration_parsing import Attribute, Relation, State, \
    ValueType


class TestParseAttribute(TestCase):
    def test_get_valid_attribute_format(self):
        for class_name in REAL_DB_STRUCTURE.keys():
            attr_cand = Attribute.get_valid_attr(class_name)
            assert isinstance(attr_cand, dict)
            for key, value in attr_cand.items():
                assert isinstance(key, str)
                assert isinstance(value, list)
                for inner_val in value:
                    assert isinstance(inner_val, str)

    def test_from_attr_egenskaber(self):

        class_name = 'bruger'
        valid_attr = Attribute.get_valid_attr(class_name)

        # interface
        attr_cand = ['brugernavn', 'abc', 'virkning', None]
        with self.assertRaises(ValueError):
            Attribute.from_attr_egenskaber(
                attr=attr_cand, valid_attr=valid_attr, class_name=class_name)
        # interface - additional information
        attr_cand = {'brugernavn': 'abc', 'virkning': None, 'brugervendtnoegle': '123'}
        with self.assertRaises(ValueError):
            Attribute.from_attr_egenskaber(
                attr=attr_cand, valid_attr=valid_attr, class_name=class_name)
        # interface - missing information
        attr_cand = {'virkning': None}
        with self.assertRaises(ValueError):
            Attribute.from_attr_egenskaber(
                attr=attr_cand, valid_attr=valid_attr, class_name=class_name)
        # interface - missing information
        attr_cand = {'brugernavn': 'abc'}
        with self.assertRaises(ValueError):
            Attribute.from_attr_egenskaber(
                attr=attr_cand, valid_attr=valid_attr,
                class_name=class_name)  # key type
        attr_cand = {123: 'abc', 'virkning': None}
        with self.assertRaises(TypeError):
            Attribute.from_attr_egenskaber(
                attr=attr_cand, valid_attr=valid_attr, class_name=class_name)
        # value type
        attr_cand = {'brugernavn': 123, 'virkning': None}
        with self.assertRaises(TypeError):
            Attribute.from_attr_egenskaber(
                attr=attr_cand, valid_attr=valid_attr, class_name=class_name)
        # virkning value
        attr_cand = {'brugernavn': 'abc', 'virkning': datetime.now()}
        with self.assertRaises(ValueError):
            Attribute.from_attr_egenskaber(
                attr=attr_cand, valid_attr=valid_attr, class_name=class_name)
        # virkning value
        attr_cand = {'brugernavn': 'abc', 'virkning': datetime.now().isoformat()}
        with self.assertRaises(ValueError):
            Attribute.from_attr_egenskaber(
                attr=attr_cand, valid_attr=valid_attr, class_name=class_name)
        # invalid key
        attr_cand = {'enhedsnavn': 'abc', 'virkning': None}
        with self.assertRaises(ValueError):
            Attribute.from_attr_egenskaber(
                attr=attr_cand, valid_attr=valid_attr, class_name=class_name)
        attr_cand = {'brugernavn': 'abc', 'virkning': None}
        expected = Attribute(key='brugernavn', value='abc', type='egenskaber',
                             value_type=ValueType.TEXT)
        actual = Attribute.from_attr_egenskaber(attr=attr_cand,
                                                valid_attr=valid_attr,
                                                class_name=class_name)
        self.assertEqual(first=expected, second=actual)

    def test_parse_registration_attributes(self):
        class_name = 'organisationfunktion'
        attrs = {'organisationfunktionegenskaber': [
            {'brugervendtnoegle': '123', 'virkning': None},
            {'funktionsnavn': 'engagement',
             'virkning': None}],
            # # covered by integration tests
            # # (could implement, but don't want double testing)
            # 'organisationfunktionudvidelser': [{'primær': '1', 'virkning': None}],
        }

        expected = [
            Attribute(key='brugervendtnoegle', value='123', type='egenskaber',
                      value_type=ValueType.TEXT),
            Attribute(key='funktionsnavn', value='engagement', type='egenskaber',
                      value_type=ValueType.TEXT),
            # Attribute(key='primær', value='1', type='udvidelser'),
        ]

        actual = Attribute.parse_registration_attributes(class_name=class_name,
                                                         attributes=attrs)
        self.assertEqual(first=expected, second=actual)


class TestParseState(TestCase):
    def test_get_valid_states_format(self):
        for class_name in REAL_DB_STRUCTURE.keys():
            state_cand = State.get_valid_states(class_name)
            assert isinstance(state_cand, dict)
            for key, value in state_cand.items():
                assert isinstance(key, str)
                assert isinstance(value, list)
                for inner_val in value:
                    assert isinstance(inner_val, str)

    def test_from_state_dict(self):

        class_name = 'bruger'
        valid_states = State.get_valid_states(class_name)

        # interface
        state_cand = ['gyldighed', 'Aktiv', 'virkning', None]
        with self.assertRaises(ValueError):
            State.from_state_dict(state=state_cand, valid_states=valid_states)

        # interface - additional information
        state_cand = {'gyldighed': 'Aktiv', 'virkning': None,
                      'brugervendtnoegle': '123'}
        with self.assertRaises(ValueError):
            State.from_state_dict(
                state=state_cand, valid_states=valid_states)
        # interface - missing information
        state_cand = {'virkning': None}
        with self.assertRaises(ValueError):
            State.from_state_dict(
                state=state_cand, valid_states=valid_states)
        # interface - missing information
        state_cand = {'gyldighed': 'Aktiv'}
        with self.assertRaises(ValueError):
            State.from_state_dict(
                state=state_cand, valid_states=valid_states)

        # key type
        state_cand = {123: 'Aktiv', 'virkning': None}
        with self.assertRaises(ValueError):
            State.from_state_dict(
                state=state_cand, valid_states=valid_states)
        # value type
        state_cand = {'gyldighed': 123, 'virkning': None}
        with self.assertRaises(ValueError):
            State.from_state_dict(
                state=state_cand, valid_states=valid_states)
        # virkning value
        state_cand = {'gyldighed': 'Aktiv', 'virkning': datetime.now()}
        with self.assertRaises(ValueError):
            State.from_state_dict(
                state=state_cand, valid_states=valid_states)
        # virkning value
        state_cand = {'gyldighed': 'Aktiv', 'virkning': datetime.now().isoformat()}
        with self.assertRaises(ValueError):
            State.from_state_dict(
                state=state_cand, valid_states=valid_states)
        # enum value
        state_cand = {'gyldighed': 'abc', 'virkning': None}
        with self.assertRaises(ValueError):
            State.from_state_dict(
                state=state_cand, valid_states=valid_states)

        # invalid key
        state_cand = {'enhedsnavn': 'Aktiv', 'virkning': None}
        with self.assertRaises(ValueError):
            State.from_state_dict(
                state=state_cand, valid_states=valid_states)
        state_cand = {'gyldighed': 'Aktiv', 'virkning': None}
        expected = State(key='gyldighed', value='Aktiv')
        actual = State.from_state_dict(state=state_cand,
                                       valid_states=valid_states)
        self.assertEqual(first=expected, second=actual)

    def test_parse_registration_state(self):
        # commonly used
        class_name = 'organisationfunktion'
        states = {'gyldighed': [{'gyldighed': 'Aktiv', 'virkning': None}]}
        expected = [State(key='gyldighed', value='Aktiv')]
        actual = State.parse_registration_states(class_name=class_name,
                                                 states=states)
        self.assertEqual(first=expected, second=actual)

        # less common, but should be valid
        class_name = 'tilstand'
        states = {
            'status': [{'status': 'Aktiv', 'virkning': None}],
            'publiceret': [{'publiceret': 'IkkePubliceret', 'virkning': None}],
        }
        expected = [
            State(key='status', value='Aktiv'),
            State(key='publiceret', value='IkkePubliceret'),
        ]
        actual = State.parse_registration_states(class_name=class_name,
                                                 states=states)
        self.assertEqual(first=expected, second=actual)


class TestParseRelation(TestCase):
    def test_get_valid_relations_format(self):
        for class_name in REAL_DB_STRUCTURE.keys():
            relation_cand = Relation.get_valid_relations(class_name)
            assert isinstance(relation_cand, list)
            for value in relation_cand:
                assert isinstance(value, str)

    def test_from_relation_list(self):

        class_name = 'organisationfunktion'
        valid_relations = Relation.get_valid_relations(class_name)
        key = 'tilknyttedebrugere'

        # interface
        relation_cand = {'virkning': None, 'objekttype': 'lederniveau',
                         'urn': 'urn:Direktion'}
        with self.assertRaises(AttributeError):
            Relation.from_relation_list(
                relation_type=key,
                relation_values=relation_cand,
                valid_relations=valid_relations)

        # interface - additional information
        relation_cand = [
            {'virkning': None, 'objekttype': 'lederniveau', 'urn': 'urn:Direktion',
             'uuid': '33268774-dc76-47b7-b54e-79d2a99a7e6a'}
        ]
        with self.assertRaises(ValueError):
            Relation.from_relation_list(
                relation_type=key,
                relation_values=relation_cand,
                valid_relations=valid_relations)

        # interface - missing information
        relation_cand = [
            {'virkning': None, 'urn': 'urn:Direktion'}
        ]
        with self.assertRaises(ValueError):
            Relation.from_relation_list(
                relation_type=key,
                relation_values=relation_cand,
                valid_relations=valid_relations)

        # interface - missing information
        relation_cand = [
            {'virkning': None, 'objekttype': 'lederniveau'}
        ]
        with self.assertRaises(ValueError):
            Relation.from_relation_list(
                relation_type=key,
                relation_values=relation_cand,
                valid_relations=valid_relations)

        # interface - missing information
        relation_cand = [
            {'objekttype': 'lederniveau', 'urn': 'urn:Direktion'}
        ]
        with self.assertRaises(ValueError):
            Relation.from_relation_list(
                relation_type=key,
                relation_values=relation_cand,
                valid_relations=valid_relations)

        # interface - missing information
        relation_cand = [
            {'urn': 'urn:Direktion'}
        ]
        with self.assertRaises(ValueError):
            Relation.from_relation_list(
                relation_type=key,
                relation_values=relation_cand,
                valid_relations=valid_relations)

        # key type
        relation_cand = [
            {'virkning': None, 123: 'lederniveau', 'urn': 'urn:Direktion'},
        ]
        with self.assertRaises(ValueError):
            Relation.from_relation_list(
                relation_type=key,
                relation_values=relation_cand,
                valid_relations=valid_relations)
        # key type
        relation_cand = [
            {'virkning': None, 'objekttype': 'lederniveau', 123: 'urn:Direktion'},
        ]
        with self.assertRaises(ValueError):
            Relation.from_relation_list(
                relation_type=key,
                relation_values=relation_cand,
                valid_relations=valid_relations)

        # value type
        relation_cand = [
            {'virkning': None, 'objekttype': 'lederniveau', 'urn': 123},
        ]
        with self.assertRaises(TypeError):
            Relation.from_relation_list(
                relation_type=key,
                relation_values=relation_cand,
                valid_relations=valid_relations)

        # value type
        relation_cand = [
            {'virkning': None, 'objekttype': 123, 'urn': 'urn:Direktion'},
        ]
        with self.assertRaises(TypeError):
            Relation.from_relation_list(
                relation_type=key,
                relation_values=relation_cand,
                valid_relations=valid_relations)

        # virkning value
        relation_cand = [
            {'virkning': datetime.now(), 'objekttype': 'lederniveau',
             'urn': 'urn:Direktion'},
        ]
        with self.assertRaises(ValueError):
            Relation.from_relation_list(
                relation_type=key,
                relation_values=relation_cand,
                valid_relations=valid_relations)

        # virkning value
        relation_cand = [
            {'virkning': datetime.now().isoformat(), 'objekttype': 'lederniveau',
             'urn': 'urn:Direktion'},
        ]
        with self.assertRaises(ValueError):
            Relation.from_relation_list(
                relation_type=key,
                relation_values=relation_cand,
                valid_relations=valid_relations)

        # invalid key
        relation_cand = [
            {'virkning': None, 'objekttype': 'lederniveau', 'abc': 'urn:Direktion'},
        ]
        with self.assertRaises(ValueError):
            Relation.from_relation_list(
                relation_type=key,
                relation_values=relation_cand,
                valid_relations=valid_relations)

        # urn with objecttype ok
        relation_values = [
            {'virkning': None, 'objekttype': 'lederniveau', 'urn': 'urn:Direktion'},
        ]
        expected = [Relation(type=key,
                             object_type='lederniveau',
                             id='urn:Direktion',
                             id_is_uuid=False)]
        actual = Relation.from_relation_list(relation_type=key,
                                             relation_values=relation_values,
                                             valid_relations=valid_relations)
        self.assertEqual(first=expected, second=actual)

        # uuid without objekttype ok
        relation_values = [
            {'virkning': None, 'objekttype': None,
             'uuid': '33268774-dc76-47b7-b54e-79d2a99a7e6a'},
        ]
        expected = [Relation(type=key,
                             object_type=None,
                             id='33268774-dc76-47b7-b54e-79d2a99a7e6a',
                             id_is_uuid=True)]
        actual = Relation.from_relation_list(relation_type=key,
                                             relation_values=relation_values,
                                             valid_relations=valid_relations)
        self.assertEqual(first=expected, second=actual)

        # multiple ok
        relation_values = [
            {'virkning': None, 'objekttype': 'lederniveau', 'urn': 'urn:Direktion'},
            {'virkning': None, 'objekttype': None,
             'uuid': '33268774-dc76-47b7-b54e-79d2a99a7e6a'}
        ]
        expected = [Relation(type=key,
                             object_type='lederniveau',
                             id='urn:Direktion',
                             id_is_uuid=False),
                    Relation(type=key,
                             object_type=None,
                             id='33268774-dc76-47b7-b54e-79d2a99a7e6a',
                             id_is_uuid=True)
                    ]
        actual = Relation.from_relation_list(relation_type=key,
                                             relation_values=relation_values,
                                             valid_relations=valid_relations)
        self.assertEqual(first=expected, second=actual)

    def test_parse_registration_relation(self):
        class_name = 'organisationfunktion'
        nul_til_en = 'organisatoriskfunktionstype'
        nul_til_mange = 'tilknyttedebrugere'
        oft_relation_values = [{'virkning': None, 'objekttype': None,
                                'uuid': '44444444-dc76-47b7-b54e-79d2a99a7e6b'}]
        tb_relation_values = [
            {'virkning': None, 'objekttype': 'lederniveau', 'urn': 'urn:Direktion'},
            {'virkning': None, 'objekttype': None,
             'uuid': '33268774-dc76-47b7-b54e-79d2a99a7e6a'}
        ]
        relations = {nul_til_en: oft_relation_values,
                     nul_til_mange: tb_relation_values}
        expected = [Relation(type=nul_til_en,
                             object_type=None,
                             id='44444444-dc76-47b7-b54e-79d2a99a7e6b',
                             id_is_uuid=True),
                    Relation(type=nul_til_mange,
                             object_type='lederniveau',
                             id='urn:Direktion',
                             id_is_uuid=False),
                    Relation(type=nul_til_mange,
                             object_type=None,
                             id='33268774-dc76-47b7-b54e-79d2a99a7e6a',
                             id_is_uuid=True),
                    ]
        actual = Relation.parse_registration_relations(class_name=class_name,
                                                       relations=relations)
        self.assertEqual(first=expected, second=actual)
