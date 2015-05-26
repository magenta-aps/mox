# encoding: utf-8

from flask import jsonify, request

from oio_rest import OIORestObject
import db


# Just a helper during debug
def j(t): return jsonify(output=t)


class Facet(OIORestObject):
    """
    Implement a Facet  - manage access to database layer from the API.
    """
    pass


class Klasse(OIORestObject):
    """
    Implement a Klasse  - manage access to database layer from the API.
    """
    pass


class Klassifikation(OIORestObject):
    """
    Implement a Klassifikation  - manage access to database from the API.
    """
    pass
