# encoding: utf-8

from oio_rest import OIORestObject, OIOStandardHierarchy


class Indsats(OIORestObject):
    """
    Implement an Indsats  - manage access to database layer from the API.
    """
    pass


class IndsatsHierarki(OIOStandardHierarchy):
    """Implement the Klassifikation Standard."""

    _name = "Indsats"
    _classes = [Indsats]
