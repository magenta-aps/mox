# encoding: utf-8
from flask import Flask, jsonify, request, url_for

app = Flask(__name__)

# This may be more elaborate and include version, etc.
BASE_URL = ''

# Just a helper during debug
j = lambda t: jsonify(help_text=t)


# Classes to handle OIO objects and object hierarchies


class OIOStandardHierarchy(object):
    """Implement API for entire hierarchy."""
    
    _classes = []

    @classmethod
    def setup_api(cls):
        for c in cls._classes:
            c.create_api(cls._name)


class OIOObject(object):
    """
    Implement an OIO object - manage access to database layer for this object.

    This class is intended to be subclassed, but not to be initialized.
    """

    @staticmethod
    def get_objects():
        raise NotImplementedError

    @staticmethod
    def get_object(uuid):
        raise NotImplementedError

    @staticmethod
    def put_object(uuid):
        raise NotImplementedError

    @staticmethod
    def create_object():
        raise NotImplementedError

    @staticmethod
    def delete_object(uuid):
        raise NotImplementedError

    @classmethod
    def create_api(cls, hierarchy):
        """Set up API with correct database access functions."""
        hierarchy = hierarchy.lower()
        class_name = cls.__name__.lower()
        class_url = u"{0}/{1}/{2}".format(BASE_URL,
                                          hierarchy,
                                          cls.__name__.lower())
        object_url = u"{0}/<uuid>".format(class_url)

        app.add_url_rule(class_url, u'_'.join([cls.__name__, 'get_objects']),
                         cls.get_objects, methods=['GET'])

        app.add_url_rule(object_url, u'_'.join([cls.__name__, 'get_object']),
                         cls.get_object, methods=['GET'])

        app.add_url_rule(object_url, u'_'.join([cls.__name__, 'put_object']),
                         cls.put_object, methods=['PUT'])

        app.add_url_rule(
            class_url, u'_'.join([cls.__name__, 'create_object']),
            cls.create_object, methods=['POST']
        )

        app.add_url_rule(
            object_url, u'_'.join([cls.__name__, 'delete_object']),
            cls.get_object, methods=['DELETE']
        )


class Facet(OIOObject):
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
        return j("Ny facet: {0}".format(request.json.get('uuid'))), 201

    @staticmethod
    def delete_object(uuid):
        # TODO: Delete facet
        return j("Slettet!"), 200


class Klasse(OIOObject):
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


class Klassifikation(OIOObject):
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


class KlassifikationsHierarki(OIOStandardHierarchy):
    """Implement the Klassifikation Standard."""

    _name = "Klassifikation"
    _classes = [Facet, Klasse, Klassifikation]


@app.route('/site-map')
def sitemap():
    links = []
    for rule in app.url_map.iter_rules():
        # Filter out rules we can't navigate to in a browser
        # and rules that require parameters
        if "GET" in rule.methods:
            links.append(str(rule))
            print rule
    return j(links)

if __name__ == '__main__':

    KlassifikationsHierarki.setup_api()
    
    app.run(debug=True)
