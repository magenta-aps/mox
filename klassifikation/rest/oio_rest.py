
from flask import jsonify, request
import db


# Just a helper during debug
def j(t): return jsonify(output=t)


class OIOStandardHierarchy(object):
    """Implement API for entire hierarchy."""

    _classes = []

    @classmethod
    def setup_api(cls, flask, base_url):
        """Set up API for the classes included in the hierarchy.

        Note that version number etc. may have to be added to the URL."""
        for c in cls._classes:
            c.create_api(cls._name, flask, base_url)


class OIORestObject(object):
    """
    Implement an OIO object - manage access to database layer for this object.

    This class is intended to be subclassed, but not to be initialized.
    """

    @classmethod
    def create_object(cls):
        """
        CREATE object, generate new UUID.
        """
        if not request.json:
            abort(400)
        note = request.json.get("Note", "")
        attributes = request.json.get("Attributter", {})
        states = request.json.get("Tilstande", {})
        relations = request.json.get("Relationer", {})
        uuid = db.create_or_import_object(cls.__name__, note, attributes,
                                          states, relations)
        return jsonify({'uuid': uuid}), 201

    @classmethod
    def get_objects(cls):
        """
        LIST or SEARCH facets, depending on parameters.
        """
        virkning_fra = request.args.get('virkningFra', None)
        virkning_til = request.args.get('virkningTil', None)
        registreret_fra = request.args.get('registreretFra', None)
        registreret_til = request.args.get('registreretTil', None)

        # TODO: Implement search

        uuid = request.args.get('uuid', None)
        if uuid is None:
            # This is not allowed, but we let the DB layer throw an exception
            uuid = []
        else:
            uuid = uuid.split(',')

        results = db.list_objects(cls.__name__, uuid, virkning_fra,
                                 virkning_til, registreret_fra,
                                 registreret_til)
        if results is None:
            results = []
        # TODO: Return JSON object key should be based on class name,
        # e.g. {"Facetter": [..]}, not {"results": [..]}
        # TODO: Include Return value
        return jsonify({'results': results})

    @classmethod
    def get_object(cls, uuid):
        """
        READ a facet, return as JSON.
        """
        return j("Hent {0} fra databasen og returner som JSON".format(uuid))

    @classmethod
    def put_object(cls, uuid):
        """
        UPDATE, IMPORT or PASSIVIZE an  object.
        """
        if not request.json:
            abort(400)
        # Get most common parameters if available.
        note = request.json.get("Note", "")
        attributes = request.json.get("Attributter", {})
        states = request.json.get("Tilstande", {})
        relations = request.json.get("Relationer", {})

        if not db.object_exists(cls.__name__, uuid):
            # Do import.
            result = db.create_or_import_object(cls.__name__, note, attributes,
                                                states, relations, uuid)
            # TODO: When connected to DB, use result properly.
            return j(u"Importeret {0}: {1}".format(cls.__name__, uuid)), 200
        else:
            "Edit or passivate."
            if (request.json.get('livscyklus', '').lower() == 'passiv'):
                # Passivate
                db.passivate_object(
                        cls.__name__, note, uuid
                )
                return j(
                            u"Passiveret {0}: {1}".format(cls.__name__, uuid)
                        ), 200
            else:
                # Edit/change
                result = db.update_object(cls.__name__, note, attributes,
                                          states, relations, uuid)
                return j(u"Opdateret {0}: {1}".format(cls.__name__, uuid)), 200
        return j(u"Forkerte parametre!"), 405

    @classmethod
    def delete_object(cls, uuid):
        # Delete facet
        #import pdb; pdb.set_trace()
        note = request.json.get("Note", "")
        class_name = cls.__name__
        result = db.delete_object(class_name, note, uuid)

        return j("Slettet {0}: {1}".format(class_name, uuid)), 200

    @classmethod
    def create_api(cls, hierarchy, flask, base_url):
        """Set up API with correct database access functions."""
        hierarchy = hierarchy.lower()
        class_name = cls.__name__.lower()
        class_url = u"{0}/{1}/{2}".format(base_url,
                                          hierarchy,
                                          cls.__name__.lower())
        uuid_regex = (
            "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}" +
            "-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}"
        )
        object_url = u'{0}/<regex("{1}"):uuid>'.format(
            class_url,
            uuid_regex
        )

        flask.add_url_rule(class_url, u'_'.join([cls.__name__, 'get_objects']),
                           cls.get_objects, methods=['GET'])

        flask.add_url_rule(object_url, u'_'.join([cls.__name__, 'get_object']),
                           cls.get_object, methods=['GET'])

        flask.add_url_rule(object_url, u'_'.join([cls.__name__, 'put_object']),
                           cls.put_object, methods=['PUT'])

        flask.add_url_rule(
            class_url, u'_'.join([cls.__name__, 'create_object']),
            cls.create_object, methods=['POST']
        )

        flask.add_url_rule(
            object_url, u'_'.join([cls.__name__, 'delete_object']),
            cls.delete_object, methods=['DELETE']
        )
