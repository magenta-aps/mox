import uuid
from werkzeug.datastructures import MultiDict

from ..db_helpers import get_attribute_names, get_attribute_fields
from ..db_helpers import get_state_names, get_relation_names, get_state_field
from ..db_helpers import get_document_part_relation_names
from ..db_helpers import DokumentVariantEgenskaberType
from ..db_helpers import DokumentDelEgenskaberType, DokumentDelRelationType


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
    """Return the string with underscores escaped by backslashes. """
    if s is None:
        return None
    return s.replace("_", "\_")


def build_registration(class_name, list_args):
    registration = {}
    for f in list_args:
        attr = registration.setdefault('attributes', {})
        for attr_name in get_attribute_names(class_name):
            if f in get_attribute_fields(attr_name):
                for attr_value in list_args[f]:
                    attr_period = {
                        f: escape_underscores(attr_value),
                        'virkning': None
                    }
                    attr.setdefault(attr_name, []).append(attr_period)

        state = registration.setdefault('states', {})
        for state_name in get_state_names(class_name):
            state_field_name = get_state_field(class_name,
                                               state_name)

            state_periods = state.setdefault(state_name, [])
            if f == state_field_name:
                for state_value in list_args[f]:
                    state_periods.append({
                        state_field_name: state_value,
                        'virkning': None
                    })

        relation = registration.setdefault('relations', {})
        if f in get_relation_names(class_name):
            relation[f] = []
            # Support multiple relation references at a time
            for rel in list_args[f]:
                relation[f].append({
                    'uuid': rel,
                    'virkning': None
                })

    if class_name == "Dokument":
        variants = registration.setdefault("variants", [])
        variant = {
            # Search on only one varianttekst is supported through REST API
            "varianttekst": escape_underscores(
                list_args.get("varianttekst", [None])[0]
            )
        }
        variants.append(variant)

        # Look for variant egenskaber
        props = []
        variant["egenskaber"] = props
        for f in list_args:
            if f in DokumentVariantEgenskaberType.get_fields():
                for val in list_args[f]:
                    props.append({
                        f: escape_underscores(val),
                        'virkning': None
                    })
        # TODO: Support deltekst, del egenskaber and del relationer
        parts = []
        variant["dele"] = parts
        part = {
            # Search on only one varianttekst is supported through REST API
            "deltekst": escape_underscores(
                list_args.get("deltekst", [None])[0]
            )
        }
        parts.append(part)

        # Look for del egenskaber
        part_props = []
        part["egenskaber"] = part_props
        for f in list_args:
            if f in DokumentDelEgenskaberType.get_fields():
                for val in list_args[f]:
                    part_props.append(
                        {
                            f: escape_underscores(val),
                            'virkning': None
                        }
                    )

        # Look for del relationer
        part_relations = part.setdefault("relationer", {})
        for f in list_args:
            if f in get_document_part_relation_names():
                part_relations[f] = []
                for rel in list_args[f]:
                    part_relations[f].append({
                        'uuid': rel,
                        'virkning': None
                    })

    return registration


def restriction_to_registration(class_name, restriction):
    states, attributes, relations = restriction

    def flatten(d):
        return [(k, v) for k, v in d.items()]

    all_fields = MultiDict(flatten(states) + flatten(attributes) +
                           flatten(relations))
    list_args = {k.lower(): all_fields.getlist(k) for k in all_fields}

    return build_registration(class_name, list_args)
