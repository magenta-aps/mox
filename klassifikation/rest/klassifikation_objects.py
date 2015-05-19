# encoding: utf-8

from flask import jsonify, request

from oio_rest import OIORestObject

# Just a helper during debug
j = lambda t: jsonify(help_text=t)


class Facet(OIORestObject):
    """
    Implement a Facet  - manage access to database layer from the API.
    """

    @staticmethod
    def get_objects():
        """
        LIST or SEARCH facets, depending on parameters.
        """
        # TODO: Implement this.
        return j("Her kommer en liste af facetter!")

    @staticmethod
    def get_object(uuid):
        """
        READ a facet, return as JSON.
        """
        return j("Hent {0} fra databasen og returnér som JSON".format(uuid))

    @staticmethod
    def put_object(uuid):
        """
        UPDATE, IMPORT or PASSIVIZE a facet.
        """
        if not request.json:
            abort(400)
        return j("Opdater {0}, fortæl om det lykkedes.".format(uuid)), 200

    @staticmethod
    def create_object():
        """
        CREATE facet, generate new UUID.
        """
        if not request.json:
            abort(400)
        note = request.json["Note"]
        attributes = request.json["Attributter"]
        states = request.json["Tilstande"]
        relations = request.json["Relationer"]
        print relations
        return j("Ny facet: {0}".format(request.json)), 201

    @staticmethod
    def delete_object(uuid):
        # TODO: Delete facet
        return j("Slettet!"), 200


class Klasse(OIORestObject):
    """
    Implement a Klasse  - manage access to database layer from the API.
    """

    @staticmethod
    def get_objects():
        """
        LIST or SEARCH Klasser, depending on parameters.
        """
        return j("Her kommer en liste af klasser!")

    @staticmethod
    def get_object(uuid):
        """
        READ a Klasse, return as JSON.
        """
        return j("Hent {0} fra databasen og returnér som JSON".format(uuid))

    @staticmethod
    def put_object(uuid):
        """
        UPDATE, IMPORT or PASSIVIZE a Klasse.
        """
        if not request.json:
            abort(400)
        return j("Opdater {0}, fortæl om det lykkedes.".format(uuid)), 200

    @staticmethod
    def create_object():
        """
        CREATE facet, generate new UUID.
        """
        if not request.json:
            abort(400)
        return j("Ny facet: {0}".format(request.json.get('uuid'))), 201

    @staticmethod
    def delete_object(uuid):
        # TODO: Delete facet
        return j("Slettet!"), 200


class Klassifikation(OIORestObject):
    """
    Implement a Klassifikation  - manage access to database from the API.
    """

    @staticmethod
    def get_objects():
        """
        LIST or SEARCH Klassfikationer, depending on parameters.
        """
        return j("Her kommer en liste af klassifikationer!")

    @staticmethod
    def get_object(uuid):
        """
        READ a Klassifikation, return as JSON.
        """
        return j("Hent {0} fra databasen og returnér som JSON".format(uuid))

    @staticmethod
    def put_object(uuid):
        """
        UPDATE, IMPORT or PASSIVIZE a Klassfikation.
        """
        if not request.json:
            abort(400)
        return j("Opdater {0}, fortæl om det lykkedes.".format(uuid)), 200

    @staticmethod
    def create_object():
        """
        CREATE facet, generate new UUID.
        """
        if not request.json:
            abort(400)
        return j("Ny facet: {0}".format(request.json.get('uuid'))), 201

    @staticmethod
    def delete_object(uuid):
        # TODO: Delete klassifikation
        return j("Slettet!"), 200

