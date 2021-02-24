# SPDX-FileCopyrightText: 2021- Magenta ApS
# SPDX-License-Identifier: MPL-2.0
from dataclasses import dataclass
from enum import Enum, auto, unique
from typing import Dict, List, Optional

from more_itertools import flatten

from oio_rest.db import db_structure
from oio_rest.db import get_field_type

VIRKNING = "virkning"
OBJECKTTYPE = "objekttype"
ATTRIBUTTER = "attributter"

TEXT_STR = "text"
BOOL_STR = "boolean"


@unique
class ValueType(Enum):
    TEXT = auto()
    BOOL = auto()

    @classmethod
    def from_string(cls, string: str) -> "ValueType":
        if string == TEXT_STR:
            return ValueType.TEXT
        elif string == BOOL_STR:
            return ValueType.BOOL

        raise ValueType(f"unexpected value {string}")


@dataclass(frozen=True)
class Attribute:
    key: str  # e.g. "brugervendtnoegle"
    value: str
    type: str  # e.g. "egenskaber" or "udvidelser"
    value_type: ValueType  # e.g. '0' could mean a bool False or the literal string

    @staticmethod
    def get_valid_attr(class_name) -> Dict[str, List[str]]:
        """
        This style object

        "attributter": {
            "egenskaber": ["brugervendtnoegle", "beskrivelse", ...],
          "udvidelser": ["abc", ...]

        :param class_name:
        :return:
        """

        return db_structure.REAL_DB_STRUCTURE[class_name][ATTRIBUTTER]

    @classmethod
    def from_attr_egenskaber(
        cls,
        attr: Dict[str, Optional[str]],
        class_name: str,
        valid_attr: Dict[str, List[str]],
    ) -> "Attribute":
        """
        deals with this sort of thing
        {'brugervendtnoegle': '123', 'virkning': None}

        OVERLY defensive, on purpose
        """
        if len(attr) != 2:
            raise ValueError(f"unexpected number of keys in attribute spec: {attr}")

        if VIRKNING not in attr.keys():
            raise ValueError(f"unexpected keys in attribute spec: {attr}")

        if attr[VIRKNING] is not None:
            raise ValueError(f"unexpected {VIRKNING} in attribute spec: {attr}")

        attr.pop(VIRKNING)
        key, val = list(attr.items())[0]  # MUST be only 1 key left
        if not isinstance(key, str):
            raise TypeError(f"expected str, got type={type(val)} of obj={val}")

        for tmp in [key, val]:
            if not isinstance(tmp, str):
                raise TypeError(
                    f"expected str, got type={type(tmp)} of obj={tmp}, from {attr}"
                )

        for attr_type, valid_attr_names in valid_attr.items():
            if key in valid_attr_names:
                return cls(
                    key,
                    val,
                    attr_type,
                    ValueType.from_string(get_field_type(class_name + attr_type, key)),
                )
        else:
            # found key not belonging anywhere
            raise ValueError(f"unexpected key={key} in attribute spec: {attr}")

    @classmethod
    def parse_registration_attributes(
        cls, class_name: str, attributes: Dict[str, List[Dict[str, Optional[str]]]]
    ) -> List["Attribute"]:
        """
        deals with the 'attributes'-value of this sort of thing
        {'attributes': {'organisationfunktionegenskaber':
         [{'brugervendtnoegle': '123', 'virkning': None},
            {'funktionsnavn': 'engagement', 'virkning': None}]}
        OVERLY defensive, on purpose
        """
        valid_attr = cls.get_valid_attr(class_name)
        valid_keys = [class_name + k for k in valid_attr.keys()]
        for attr_key in attributes.keys():
            if attr_key not in valid_keys:
                raise ValueError(f"unexpected value {attr_key} not in {valid_keys}")

        return [
            cls.from_attr_egenskaber(a, class_name, valid_attr)
            for attr_list in attributes.values()
            for a in attr_list
        ]


@dataclass(frozen=True)
class State:
    key: str
    value: str

    @staticmethod
    def get_valid_states(class_name: str) -> Dict[str, List[str]]:
        # "tilstande": {
        #     "gyldighed": ["Aktiv", "Inaktiv"]
        return dict(db_structure.REAL_DB_STRUCTURE[class_name]["tilstande"])

    @classmethod
    def parse_registration_states(
        cls, class_name: str, states: Dict[str, List[Dict[str, Optional[str]]]]
    ) -> List["State"]:
        """
        deals with 'states'-value of this sort of thing
        'states': {'gyldighed': [{'gyldighed': 'Aktiv', 'virkning': None}]}

        OVERLY defensive, on purpose

        will utilize that the keys are repeated in the "inner" value
        """
        valid_states = cls.get_valid_states(class_name)

        if not (set(states.keys()) <= set(valid_states.keys())):
            raise ValueError(f"unexpected keys in {states}")

        return [
            cls.from_state_dict(state, valid_states)
            for state_list in states.values()
            for state in state_list
        ]

    @classmethod
    def from_state_dict(
        cls, state: Dict[str, Optional[str]], valid_states: Dict[str, List[str]]
    ) -> "State":
        """
        deals with this sort of thing
        [{'gyldighed': 'Aktiv', 'virkning': None}]

        OVERLY defensive, on purpose
        """

        if len(state) != 2:
            raise ValueError(f"unexpected number of keys in state spec: {state}")

        if VIRKNING not in state.keys():
            raise ValueError(f"unexpected keys in state spec: {state}")

        if state[VIRKNING] is not None:
            raise ValueError(f"unexpected {VIRKNING} in state spec: {state}")

        state.pop(VIRKNING)
        key, val = list(state.items())[0]  # MUST be only 1 key left
        if key not in valid_states.keys():
            raise ValueError(f"unexpected key={key} in attribute spec: {state}")

        if val not in valid_states[key]:
            raise ValueError(f"unexpected value={val} in attribute spec: {state}")

        for tmp in [key, val]:
            if not isinstance(tmp, str):
                raise TypeError(
                    f"expected str, got type={type(tmp)} of obj={tmp}, from {state}"
                )
        return cls(key, val)


@dataclass(frozen=True)
class Relation:  # OVERLY defensive, on purpose
    """
    API-format:
    <relation>:<objecttype>=<uuid|urn>
    """

    type: str
    object_type: Optional[str]
    id: str
    id_is_uuid: bool  # else, it is urn

    @staticmethod
    def get_valid_relations(class_name: str) -> List[str]:
        return db_structure.REAL_DB_STRUCTURE[class_name].get(
            "relationer_nul_til_en", []
        ) + db_structure.REAL_DB_STRUCTURE[class_name].get(
            "relationer_nul_til_mange", []
        )

    @classmethod
    def from_relation_list(
        cls,
        relation_type: str,
        relation_values: List[Dict[str, Optional[str]]],
        valid_relations: List[str],
    ) -> List["Relation"]:
        """
        deals with this sort of thing
        'tilknyttedebrugere':
        [{'virkning': None, 'objekttype': 'lederniveau', 'urn': 'urn:Direktion'},
         {'virkning': None, 'objekttype': None,
         'uuid': '33268774-dc76-47b7-b54e-79d2a99a7e6a'}]
        OVERLY defensive, on purpose
        """

        if relation_type not in valid_relations:
            raise ValueError(
                f"unexpected relation {relation_type}, legal values: {valid_relations}"
            )

        ret = []
        for relation in relation_values:
            if VIRKNING not in relation.keys():
                raise ValueError(f"unexpected keys in relation spec: {relation}")

            if relation[VIRKNING] is not None:
                raise ValueError(f"unexpected {VIRKNING} in relation spec: {relation}")

            if len(relation) != 3:
                raise ValueError(
                    f"unexpected number of keys in relation spec: {relation}"
                )

            relation.pop(VIRKNING)

            if OBJECKTTYPE not in relation.keys():
                raise ValueError(f"unexpected keys in relation spec: {relation}")

            current_objekttype = relation.pop(OBJECKTTYPE)
            if not (current_objekttype is None or isinstance(current_objekttype, str)):
                raise TypeError(
                    f"unexpected type of {current_objekttype}, "
                    f"type={type(current_objekttype)} in relation spec: {relation}"
                )

            key, val = list(relation.items())[0]  # MUST be only 1 key left
            if key == "uuid":
                is_uuid = True
            elif key == "urn":
                is_uuid = False
            else:
                raise ValueError(f"unexpected {key} in relation spec: {relation}")

            if not isinstance(val, str):
                raise TypeError(
                    f"expected str, got type={type(val)} of obj={val}, from {relation}"
                )

            ret.append(
                cls(
                    type=relation_type,
                    object_type=current_objekttype,
                    id=val,
                    id_is_uuid=is_uuid,
                )
            )
        return ret

    @classmethod
    def parse_registration_relations(
        cls, class_name: str, relations: Dict[str, List[Dict[str, Optional[str]]]]
    ) -> List["Relation"]:
        """
        deals with key-value pairs of this sort of thing
        'relations': {
            'tilknyttedebrugere':
            [{'virkning': None, 'objekttype': 'lederniveau', 'urn': 'urn:Direktion'},
             {'virkning': None, 'objekttype': 'lederniveau', 'urn': 'urn:Leder'}],
            'tilknyttedeenheder': [{'virkning': None, 'objekttype': None,
                                    'uuid': '33268774-dc76-47b7-b54e-79d2a99a7e6a'}]}}
        OVERLY defensive, on purpose

        will utilize that the keys are repeated in the "inner" value
        """
        valid_relations = cls.get_valid_relations(class_name)

        if not (set(relations.keys()) <= set(valid_relations)):
            raise ValueError(
                f"unexpected keys in {relations}. valid_relations={valid_relations}"
            )

        return list(
            flatten(
                [
                    cls.from_relation_list(
                        relation_type, relation_list, valid_relations
                    )
                    for relation_type, relation_list in relations.items()
                ]
            )
        )
