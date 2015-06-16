# encoding: utf-8

from flask import jsonify, request

from oio_rest import OIORestObject, OIOStandardHierarchy


class Bruger(OIORestObject):
    """
    Implement a Bruger  - manage access to database layer from the API.
    """
    pass


class InteresseFaellesskab(OIORestObject):
    """
    Implement a Klasse  - manage access to database layer from the API.
    """
    pass


class ItSystem(OIORestObject):
    """
    Implement a Klassifikation  - manage access to database from the API.
    """
    pass


class Organisation(OIORestObject):
    """
    Implement a Klassifikation  - manage access to database from the API.
    """
    pass


class OrganisationEnhed(OIORestObject):
    """
    Implement a Klassifikation  - manage access to database from the API.
    """
    pass


class OrganisationFunktion(OIORestObject):
    """
    Implement a Klassifikation  - manage access to database from the API.
    """
    pass


class OrganisationsHierarki(OIOStandardHierarchy):
    """Implement the Organisation Standard."""

    _name = "Organisation"
    _classes = [Bruger, InteresseFaellesskab, ItSystem, Organisation,
                OrganisationEnhed, OrganisationFunktion]
