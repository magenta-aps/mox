from werkzeug.datastructures import MultiDict

from ..db_helpers import get_attribute_names, get_attribute_fields
from ..db_helpers import get_state_names, get_relation_names, get_state_field


def build_registration(class_name, list_args):
    registration = {}
    for f in list_args:
        attr = registration.setdefault('attributter', {})
        for attr_name in get_attribute_names(class_name):
            if f in get_attribute_fields(attr_name):
                for attr_value in list_args[f]:
                    attr_period = {'virkning': None, f: attr_value}
                    attr.setdefault(attr_name, []).append(attr_period)

        state = registration.setdefault('tilstande', {})
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

        relation = registration.setdefault('relationer', {})
        if f in get_relation_names(class_name):
            relation[f] = []
            # Support multiple relation references at a time
            for rel in list_args[f]:
                relation[f].append({
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
