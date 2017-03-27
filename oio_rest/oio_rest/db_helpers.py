""""Encapsulate details about the database structure."""
from collections import namedtuple
from urlparse import urlparse
from flask import request

from psycopg2._range import DateTimeTZRange
from psycopg2.extensions import adapt as psyco_adapt, ISQLQuote
from psycopg2.extensions import register_adapter as psyco_register_adapter
from contentstore import content_store

from db_structure import REAL_DB_STRUCTURE as db_struct
from custom_exceptions import BadRequestException

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
    return db_struct[class_name.lower()]['tilstande']


def get_state_field(class_name, state_name):
    """Return the name of the state field for the given state.
    This usually follows the convention of appending 'status' to the end.
    """
    return state_name + 'status'


_relation_names = {}


def get_relation_names(class_name):
    "Return the list of all recognized relations for this class."
    if len(_relation_names) == 0:
        for c in db_struct:
            _relation_names[c] = [
                a for a in db_struct[c]['relationer_nul_til_en'] +
                [b for b in db_struct[c]['relationer_nul_til_mange']]
                ]
    return _relation_names[class_name.lower()]


def get_document_part_relation_names():
    """Return the list of all recognized relations for DokumentDel"""
    return ["underredigeringaf"]


# Helper classers for adapting special types
Soegeord = namedtuple('KlasseSoegeordType', 'identifier description category')
OffentlighedUndtaget = namedtuple(
    'OffentlighedUndtagetType', 'alternativtitel hjemmel'
)
JournalNotat = namedtuple('JournalNotatType', 'titel notat format')
JournalDokument = namedtuple(
    'JournalPostDokumentAttrType', 'dokumenttitel offentlighedundtaget'
)
AktoerAttr = namedtuple(
    'AktivitetAktoerAttr',
    'accepteret obligatorisk repraesentation_uuid repraesentation_urn'
)
VaerdiRelationAttr = namedtuple(
    'TilstandVaerdiRelationAttrType',
    'forventet nominelvaerdi'
)


def input_list(_type, input, key):
    """Take a value with key from the input and return a list.

    _type.input is called for each value in the list. If the key is not
    found in the input, then None is returned."""
    values = input.get(key, None)
    if values is None:
        return None
    else:
        return [_type.input(v) for v in values]


def input_dict_list(_type, input):
    """Take a dict input and return a generator.

    Input is assumed to be a dict with list values.

    _type.input is called for each value in the list corresponding to each
    key. If the input is None, then None is returned."""
    if input is None:
        return None
    else:
        return [_type.input(k, v) for k in input.keys() for v in input[k]]


def to_bool(s):
    """Convert string to boolean. Passes through bool and None values."""
    if isinstance(s, bool):
        return s
    elif s is None:
        return None
    else:
        if s in ("True", "true", "1"):
            return True
        elif s in ("False", "false", "0"):
            return False
        raise ValueError("%s is not a valid boolean value" % s)


class Searchable(object):
    """Mixin class for searchable namedtuples."""
    non_searchable_fields = ('virkning',)

    @classmethod
    def get_fields(cls):
        """Return tuple of searchable fields."""
        if 'virkning' in cls._fields:
            return tuple(set(cls._fields) - set(cls.non_searchable_fields))
        else:
            return cls._fields


class DokumentVariantType(namedtuple('DokumentVariantType',
                                     'varianttekst egenskaber dele')):
    @classmethod
    def input(cls, i):
        if i is None:
            return None
        return cls(
            i.get("varianttekst", None),
            input_list(DokumentVariantEgenskaberType, i, "egenskaber"),
            input_list(DokumentDelType, i, "dele")
        )


class DokumentVariantEgenskaberType(Searchable, namedtuple(
    'DokumentVariantEgenskaberType',
    'arkivering delvisscannet offentliggoerelse produktion virkning'
)):
    @classmethod
    def input(cls, i):
        if i is None:
            return None
        return cls(
            to_bool(i.get("arkivering", None)),
            to_bool(i.get("delvisscannet", None)),
            to_bool(i.get("offentliggoerelse", None)),
            to_bool(i.get("produktion", None)),
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
            input_dict_list(DokumentDelRelationType, i.get("relationer", None))
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


class DokumentDelEgenskaberType(Searchable, namedtuple(
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

    @classmethod
    def input(cls, i):
        if i is None:
            return None
        indhold = i.get('indhold', None)

        # If the content URL is provided, and we are not doing a read
        # operation, save the uploaded file
        if indhold is not None and indhold != "" and request.method != 'GET':
            try:
                o = urlparse(indhold)
            except ValueError:
                raise BadRequestException(
                    "The parameter \"indhold\" contained "
                    "an invalid URL: \"%s\"" % indhold)
            # If the user is uploading a file, then handle the upload
            if o.scheme == 'field':
                # Get FileStorage object referenced by indhold field
                f = cls._get_file_storage_for_content_url(indhold)

                # Save the file and get the URL for the saved file
                indhold = content_store.save_file_object(f)
            else:
                # Otherwise, just accept whatever URL they pass.
                pass

        return cls(
            i.get('indeks', None),
            indhold,
            i.get('lokation', None),
            i.get('mimetype', None),
            Virkning.input(i.get('virkning', None))
        )


class DokumentDelRelationType(namedtuple(
    'DokumentDelRelationType',
    'reltype virkning relmaaluuid relmaalurn objekttype'
)):
    @classmethod
    def input(cls, key, i):
        if i is None:
            return None
        return cls(
            key,
            Virkning.input(i.get('virkning', None)),
            i.get('uuid', None),
            i.get('urn', None),
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

    def prepare_and_adapt(self, x):
        x = psyco_adapt(x)
        if hasattr(x, 'prepare'):
            x.prepare(self._conn)
        return x

    def getquoted(self):
        values = map(self.prepare_and_adapt, self._tuple_obj)
        values = [v.getquoted() for v in values]
        sql = ('ROW(' + ','.join(values) + ') :: ' +
               self._tuple_obj.__class__.__name__)
        return sql

    def __str__(self):
        return self.getquoted()


class AktoerAttrAdapter(NamedTupleAdapter):

    def getquoted(self):
        values = map(self.prepare_and_adapt, self._tuple_obj)
        values = [v.getquoted() for v in values]
        qaa = AktoerAttr(*values)  # quoted_aktoer_attr
        values = [
            qaa.obligatorisk + '::AktivitetAktoerAttrObligatoriskKode',
            qaa.accepteret + '::AktivitetAktoerAttrAccepteretKode',
            qaa.repraesentation_uuid + '::uuid',
            qaa.repraesentation_urn
        ]

        sql = ('ROW(' + ','.join(values) + ') :: ' +
               self._tuple_obj.__class__.__name__)
        return sql


psyco_register_adapter(Virkning, NamedTupleAdapter)
psyco_register_adapter(Soegeord, NamedTupleAdapter)
psyco_register_adapter(OffentlighedUndtaget, NamedTupleAdapter)
psyco_register_adapter(JournalNotat, NamedTupleAdapter)
psyco_register_adapter(JournalDokument, NamedTupleAdapter)
psyco_register_adapter(VaerdiRelationAttr, NamedTupleAdapter)
psyco_register_adapter(AktoerAttr, AktoerAttrAdapter)

# Dokument variants
psyco_register_adapter(DokumentVariantType, NamedTupleAdapter)
psyco_register_adapter(DokumentVariantEgenskaberType, NamedTupleAdapter)
# Dokument parts
psyco_register_adapter(DokumentDelType, NamedTupleAdapter)
psyco_register_adapter(DokumentDelEgenskaberType, NamedTupleAdapter)
psyco_register_adapter(DokumentDelRelationType, NamedTupleAdapter)

if __name__ == '__main__':
    print '\n'.join(sorted(db_struct))
