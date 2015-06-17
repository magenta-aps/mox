""""Encapsulate details about the database structure."""

from psycopg2.extensions import adapt as psyco_adapt, ISQLQuote
from psycopg2.extensions import register_adapter as psyco_register_adapter

from settings import REAL_DB_STRUCTURE as db_struct


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


# Helper classers for adapting special types

class Soegeord(object):
    def __init__(self, i=None, d=None, c=None):
        self.identifier = i
        self.description = d
        self.category = c


class SoegeordAdapter(object):

    def __init__(self, soegeord):
        self._soegeord = soegeord

    def __conform__(self, proto):
        if proto is ISQLQuote:
            return self

    def getquoted(self):
        values = map(psyco_adapt, [
            self._soegeord.identifier,
            self._soegeord.description,
            self._soegeord.category
        ])
        values = [v.getquoted() for v in values]
        sql = 'ROW(' + ','.join(values) + ') :: KlasseSoegeordType'
        print values
        return sql

    def __str__(self):
        return self.getquoted()

psyco_register_adapter(Soegeord, SoegeordAdapter)
