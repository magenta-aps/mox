""""Encapsulate details about the database structure."""

from settings import DATABASE_STRUCTURE as db_struct

_attribute_fields = {}


def get_attribute_fields(attribute_name):
    """Return the field names from the PostgreSQL type in question.

    """

    if len(_attribute_fields) == 0:
        "Initialize attr fields for ease of use."
        for c in db_struct:
            for a in db_struct[c]["attributter"]:
                _attribute_fields[
                    c + a
                ] = db_struct[c]["attributter"][a] + ['virkning']
    return _attribute_fields[attribute_name.lower()]


_attribute_names = {}


def get_attribute_names(class_name):
    "Return the list of all recognized attributes for this class."
    if len(_attribute_names) == 0:
        for c in db_struct:
            _attribute_names[c] = [
                c + a for a in db_struct[c]['attributter']
            ]
    return _attribute_names[class_name.lower()]


_state_names = {}


def get_state_names(class_name):
    "Return the list of all recognized attributes for this class."
    if len(_state_names) == 0:
        for c in db_struct:
            _state_names[c] = [
                c + a for a in db_struct[c]['tilstande']
            ]
    return _state_names[class_name.lower()]
