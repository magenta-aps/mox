""""Encapsulate details about the database structure."""
from collections import namedtuple
from urlparse import urlparse
from flask import request
import psycopg2
from psycopg2._range import DateTimeTZRange

from psycopg2.extensions import adapt as psyco_adapt, ISQLQuote
from psycopg2.extensions import register_adapter as psyco_register_adapter
from contentstore import content_store

from settings import REAL_DB_STRUCTURE as db_struct
from utils.exceptions import BadRequestException

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


def input_list(_type, input, key):
    """Take a value with key from the input and return a list.

    _type.input is called for each value in the list. If the key is not
    found in the input, then None is returned."""
    values = input.get(key, None)
    if values is None:
        return values
    else:
        return [_type.input(v) for v in values]


class DokumentVariantType(
    namedtuple('DokumentVariantType', 'varianttekst egenskaber dele')):
    @classmethod
    def input(cls, i):
        if i is None:
            return None
        return cls(
            i.get("varianttekst", None),
            input_list(DokumentVariantEgenskaberType, i, "egenskaber"),
            input_list(DokumentDelType, i, "dele")
        )


class DokumentVariantEgenskaberType(namedtuple(
    'DokumentVariantEgenskaberType',
    'arkivering delvisscannet offentliggoerelse produktion virkning'
)):
    @classmethod
    def input(cls, i):
        if i is None:
            return None
        return cls(
            i.get("arkivering", None),
            i.get("delvisscannet", None),
            i.get("offentliggoerelse", None),
            i.get("produktion", None),
            Virkning.input(i.get("virkning", None))
        )


class DokumentDelType(namedtuple(
    'DokumentDelType',
    'deltekst egenskaber relationer'
)):
    @classmethod
    def input(cls, i):
        if i is None:
            return None
        return cls(
            i.get('deltekst', None),
            input_list(DokumentDelEgenskaberType, i, "egenskaber"),
            input_list(DokumentDelRelationType, i, "relationer")
        )


class Virkning(namedtuple('Virkning',
                          'timeperiod aktoerref aktoertypekode notetekst')):
    @classmethod
    def input(cls, i):
        if i is None:
            return None
        return cls(
            DateTimeTZRange(
                i.get("from", None),
                i.get("to", None)
            ),
            i.get("aktoerref", None),
            i.get("aktoertypekode", None),
            i.get("notetekst", None)
        )


class DokumentDelEgenskaberType(namedtuple(
    'DokumentDelEgenskaberType',
    'indeks indhold lokation mimetype virkning'
)):
    @classmethod
    def _get_file_storage_for_content_url(cls, url):
        """
        Return a FileStorage object for the form field specified by the URL.

        The URL uses the scheme 'field', and its path points to a form field
        which contains the uploaded file. For example, for a URL of 'field:f1',
        this method would return the FileStorage object for the file
        contained in form field 'f1'.
        """
        o = urlparse(url)
        if o.scheme == 'field':
            field_name = o.path
            file_obj = request.files.get(field_name, None)
            if file_obj is None:
                raise BadRequestException(
                    ('The content URL "%s" referenced the field "%s", but it '
                     'was not present in the request.') % (url, o.path)
                )
            return file_obj
        else:
            raise BadRequestException(
                'The content field referenced an unsupported '
                'scheme or was invalid. The URLs must be of the'
                'form: field:<form-field>, where <form-field> '
                'is the name of the field in the '
                'multipart/form-data-encoded request that '
                'contains the file binary data.'
            )

    @classmethod
    def input(cls, i):
        if i is None:
            return None
        content_url = i.get('indhold', None)

        # Get FileStorage object referenced by indhold field
        f = cls._get_file_storage_for_content_url(content_url)

        # Save the file and get the URL for the saved file
        stored_content_url = content_store.save_file_object(f)

        return cls(
            i.get('indeks', None),
            stored_content_url,
            i.get('lokation', None),
            i.get('mimetype', None),
            Virkning.input(i.get('virkning', None))
        )


class DokumentDelRelationType(namedtuple(
    'DokumentDelRelationType',
    'reltype virkning relmaaluuid relmaalurn objekttype'
)):
    @classmethod
    def input(cls, i):
        if i is None:
            return None
        return cls(
            i.get('reltype', None),
            Virkning.input(i.get('virkning', None)),
            i.get('relmaaluuid', None),
            i.get('relmaalurn', None),
            i.get('objekttype', None),
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
            if hasattr(x, 'prepare'):
                x.prepare(self._conn)
            return x

        values = map(prepare_and_adapt, self._tuple_obj)
        values = [v.getquoted() for v in values]
        sql = 'ROW(' + ','.join(values) + ') :: ' + \
              self._tuple_obj.__class__.__name__
        return sql

    def __str__(self):
        return self.getquoted()


psyco_register_adapter(Virkning, NamedTupleAdapter)
psyco_register_adapter(Soegeord, NamedTupleAdapter)
psyco_register_adapter(OffentlighedUndtaget, NamedTupleAdapter)
psyco_register_adapter(JournalNotat, NamedTupleAdapter)
psyco_register_adapter(JournalDokument, NamedTupleAdapter)

# Dokument variants
psyco_register_adapter(DokumentVariantType, NamedTupleAdapter)
psyco_register_adapter(DokumentVariantEgenskaberType, NamedTupleAdapter)
# Dokument parts
psyco_register_adapter(DokumentDelType, NamedTupleAdapter)
psyco_register_adapter(DokumentDelEgenskaberType, NamedTupleAdapter)
psyco_register_adapter(DokumentDelRelationType, NamedTupleAdapter)
