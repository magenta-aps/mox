""""Encapsulate details about the database structure."""
from collections import namedtuple
import psycopg2

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


def get_field_type(attribute_name, field_name):
    for c in db_struct:
        if "attributter_type_override" in db_struct[c]:
            for a, fs in db_struct[c]["attributter_type_override"].items():
                if attribute_name == c + a:
                    if field_name in fs:
                        return fs[field_name]
    return "text"

_attribute_names = {}


def get_relation_field_type(class_name, field_name):
    class_info = db_struct[class_name.lower()]
    if "relationer_type_override" in class_info:
        if field_name in class_info["relationer_type_override"]:
            return class_info["relationer_type_override"][field_name]
    return "text"


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
    "Return the list of all recognized states for this class."
    if len(_state_names) == 0:
        for c in db_struct:
            _state_names[c] = [
                c + a for a in db_struct[c]['tilstande']
            ]
    return _state_names[class_name.lower()]


def get_state_field(class_name, state_name):
    """Return the name of the state field for the given state.
    This usually follows the convention of appending 'status' to the end.
    """
    return state_name.lstrip(class_name.lower()) + 'status'

_relation_names = {}


def get_relation_names(class_name):
    "Return the list of all recognized relations for this class."
    if len(_relation_names) == 0:
        for c in db_struct:
            _relation_names[c] = [
                a for a in db_struct[c]['relationer_nul_til_en']
                + [b for b in db_struct[c]['relationer_nul_til_mange']]
                ]
    return _relation_names[class_name.lower()]


# Helper classers for adapting special types

Soegeord = namedtuple('KlasseSoegeordType', 'identifier description category')
OffentlighedUndtaget = namedtuple(
    'OffentlighedUndtagetType', 'alternativtitel hjemmel'
)
JournalNotat = namedtuple('JournalNotatType', 'titel notat format')
JournalDokument = namedtuple(
    'JournalPostDokumentAttrType', 'dokumenttitel offentlighedundtaget'
)


class NamedTupleAdapter(object):
    """Adapt namedtuples, while performing a cast to the tuple's classname."""
    def __init__(self, tuple_obj):
        self._tuple_obj = tuple_obj

    def __conform__(self, proto):
        if proto is ISQLQuote:
            return self

    def prepare(self, conn):
        self._conn = conn

    def getquoted(self):
        def prepare_and_adapt(x):
            x = psyco_adapt(x)
            x.prepare(self._conn)
            return x
        values = map(prepare_and_adapt, self._tuple_obj)
        values = [v.getquoted() for v in values]
        sql = 'ROW(' + ','.join(values) + ') :: ' + \
              self._tuple_obj.__class__.__name__
        return sql

    def __str__(self):
        return self.getquoted()

psyco_register_adapter(Soegeord, NamedTupleAdapter)
psyco_register_adapter(OffentlighedUndtaget, NamedTupleAdapter)
psyco_register_adapter(JournalNotat, NamedTupleAdapter)
psyco_register_adapter(JournalDokument, NamedTupleAdapter)
