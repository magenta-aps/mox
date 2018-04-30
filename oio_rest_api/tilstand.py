# encoding: utf-8

from oio_rest import OIORestObject, OIOStandardHierarchy


class Tilstand(OIORestObject):
    """
    Implement a Tilstand - manage access to database layer from the API.
    """
    pass


class TilstandsHierarki(OIOStandardHierarchy):
    """Implement the Klassifikation Standard."""

    _name = "Tilstand"
    _classes = [Tilstand]
