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
        return j("Hent {0} fra databasen og returner som JSON".format(uuid))

    @staticmethod
    def put_object(uuid):
        """
        UPDATE, IMPORT or PASSIVIZE a facet.
        """
        if not request.json:
            abort(400)
        if not db.facet_exists(uuid):
            "Do import."
            note = request.json["Note"]
            attributes = request.json["Attributter"]
            states = request.json["Tilstande"]
            relations = request.json["Relationer"]
            result = db.create_or_import_facet(note, attributes, states,
                                               relations, uuid)

            return j(u"Importeret facet: {0}".format(uuid)), 200
        else:
            "Edit or passivate."
            if (request.json.get('livscyklus', '').lower() == 'passiv'):
                # Passivate
                db.passivate_facet(request.json.get('Note', ''), uuid)
                return j(u"Passiveret: {0}".format(uuid)), 200
            else:
                # Edit/change
                pass
        return j(u"Forkerte parametre!"), 405

    @staticmethod
    def create_object():
        """
        CREATE facet, generate new UUID.
        """
        if not request.json:
            abort(400)
        print "JSON", request.json
        note = request.json["Note"]
        attributes = request.json["Attributter"]
        states = request.json["Tilstande"]
        relations = request.json["Relationer"]
        result = db.create_or_import_facet(note, attributes, states, relations)
        # TODO: Return properly, when this is implemented.
        return j(u"Ny facet: {0}".format(result)), 201

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
