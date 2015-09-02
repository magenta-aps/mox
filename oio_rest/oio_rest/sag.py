# encoding: utf-8

from oio_rest import OIORestObject, OIOStandardHierarchy


class Sag(OIORestObject):
    """
    Implement a Sag  - manage access to database layer from the API.
    """
    pass


class SagsHierarki(OIOStandardHierarchy):
    """Implement the Klassifikation Standard."""

    _name = "Sag"
    _classes = [Sag]
