# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


import itertools
import uuid

from werkzeug.datastructures import MultiDict

from oio_rest.db.db_helpers import get_attribute_names, get_attribute_fields
from oio_rest.db.db_helpers import get_state_names, get_relation_names
from oio_rest.db.db_helpers import get_document_part_relation_names
from oio_rest.db.db_helpers import DokumentVariantEgenskaberType
from oio_rest.db.db_helpers import DokumentDelEgenskaberType


def is_urn(s):
    """Return whether string is likely a URN."""
    return s.startswith("urn:") or s.startswith("URN:")


def is_uuid(s):
    """Return whether the string is a UUID (and not a URN)"""
    if not is_urn(s):
        try:
            uuid.UUID(s)
            return True
        except ValueError:
            return False


def escape_underscores(s):
    """Return the string with underscores escaped by backslashes."""
    if s is None:
        return None
    return s.replace("_", r"\_")


def build_relation(value, objekttype=None, virkning=None):
    relation = {"virkning": virkning, "objekttype": objekttype}
    if is_uuid(value):
        relation["uuid"] = value
    elif is_urn(value):
        relation["urn"] = value
    else:
        raise ValueError(
            "Relation has an invalid value (not a UUID or URN) '%s'" % value
        )
    return relation


def split_param(value):
    """Return a tuple of the first and second item in a colon-separated str.

    E.g. if the input is "a:b", returns ("a", "b").
    If the input does not contain a color, e.g. "a", then ("a", None) is
    returned.
    """
    try:
        a, b = value.split(":")
        return a, b
    except ValueError:
        return value, None


def to_lower_param(s):
    """Return the colon-separated string with the first
    item in lowercase. The second item is left untouched."""
    try:
        a, b = s.split(":")
        return "%s:%s" % (a.lower(), b)
    except ValueError:
        return s.lower()


ACCEPTED_JOURNAL_POST_PARAMS = set(
    """journalpostkode
journalnotat.titel
journalnotat.notat
journalnotat.format
journaldokument.dokumenttitel
journaldokument.offentlighedundtaget.alternativtitel
journaldokument.offentlighedundtaget.hjemmel""".split()
)


def dict_from_dot_notation(notation, value):
    """Return a nested dict where each key is an element of the
    dot-separated string, and the value of the innermost dict's key is
    equal to the value.

    Example:
    >>> dict_from_dot_notation("a.b.c", 1)
    {'a': {'b': {'c': 1}}}
    """
    path = notation.split(".")
    element = path.pop(0)
    if len(path) == 0:
        return {element: value}
    else:
        return {element: dict_from_dot_notation(".".join(path), value)}


def add_journal_post_relation_fields(param, values, relation):
    """Add journalpost-specific parameters to the relations list."""
    if param in ACCEPTED_JOURNAL_POST_PARAMS:
        relation.setdefault("journalpost", [])
        # Build a separate relation dict for each sub-field value
        for value in values:
            # All fields support wildcards except journalpostkode
            if param != "journalpostkode":
                value = escape_underscores(value)
            relation_dict = dict_from_dot_notation(param, value)
            relation_dict["virkning"] = None
            relation["journalpost"].append(relation_dict)


def build_registration(class_name, list_args):
    registration = {}
    for f in list_args:
        attr = registration.setdefault("attributes", {})
        for attr_name in get_attribute_names(class_name):
            if f in get_attribute_fields(attr_name):
                for attr_value in list_args[f]:
                    attr_period = {f: escape_underscores(attr_value), "virkning": None}
                    attr.setdefault(attr_name, []).append(attr_period)

        state = registration.setdefault("states", {})
        for state_name in get_state_names(class_name):
            state_periods = state.setdefault(state_name, [])
            if f == state_name:
                for state_value in list_args[f]:
                    state_periods.append({state_name: state_value, "virkning": None})

        relation = registration.setdefault("relations", {})
        rel_name, objekttype = split_param(f)
        if rel_name in get_relation_names(class_name):
            relation.setdefault(rel_name, [])

            # Support multiple relation references at a time
            for rel in list_args[f]:
                relation[rel_name].append(build_relation(rel, objekttype))

        add_journal_post_relation_fields(f, list_args[f], relation)

    if class_name == "Dokument":
        variants = registration.setdefault("variants", [])
        variant = {
            # Search on only one varianttekst is supported through REST API
            "varianttekst": escape_underscores(list_args.get("varianttekst", [None])[0])
        }
        variants.append(variant)

        # Look for variant egenskaber
        props = []
        variant["egenskaber"] = props
        for f in list_args:
            if f in DokumentVariantEgenskaberType.get_fields():
                for val in list_args[f]:
                    props.append({f: escape_underscores(val), "virkning": None})

        parts = []
        variant["dele"] = parts
        part = {
            # Search on only one varianttekst is supported through REST API
            "deltekst": escape_underscores(list_args.get("deltekst", [None])[0])
        }
        parts.append(part)

        # Look for del egenskaber
        part_props = []
        part["egenskaber"] = part_props
        for f in list_args:
            if f in DokumentDelEgenskaberType.get_fields():
                for val in list_args[f]:
                    part_props.append({f: escape_underscores(val), "virkning": None})

        # Look for del relationer
        part_relations = part.setdefault("relationer", {})
        for f in list_args:
            rel_name, objekttype = split_param(f)
            if rel_name in get_document_part_relation_names():
                part_relations[rel_name] = []
                for rel in list_args[f]:
                    part_relations[rel_name].append(build_relation(rel, objekttype))

    return registration


def restriction_to_registration(class_name, restriction):
    states, attributes, relations = restriction

    all_fields = MultiDict(
        itertools.chain(
            states.items(),
            attributes.items(),
            relations.items(),
        )
    )
    list_args = {k.lower(): all_fields.getlist(k) for k in all_fields}

    return build_registration(class_name, list_args)
