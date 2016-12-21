# encoding: utf-8

from oio_rest import OIORestObject, OIOStandardHierarchy


class Aktivitet(OIORestObject):
    """
    Implement an Aktivitet  - manage access to database layer from the API.
    """
    pass


class AktivitetsHierarki(OIOStandardHierarchy):
    """Implement the Klassifikation Standard."""

    _name = "Aktivitet"
    _classes = [Aktivitet]
