from flask import jsonify, request

import db
from db_helpers import get_attribute_names, get_attribute_fields, \
    get_state_names, get_relation_names, get_state_field

from datetime import datetime


# Just a helper during debug
def j(t):
    return jsonify(output=t)


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
            return jsonify({'uuid': None}), 400
        note = request.json.get("note", "")
        attributes = request.json.get("attributter", {})
        states = request.json.get("tilstande", {})
        relations = request.json.get("relationer", {})
        uuid = db.create_or_import_object(cls.__name__, note, attributes,
                                          states, relations)
        return jsonify({'uuid': uuid}), 201

    @classmethod
    def get_objects(cls):
        """
        LIST or SEARCH objects, depending on parameters.
        """
        # Convert arguments to lowercase, getting them as lists
        list_args = {k.lower(): request.args.getlist(k)
                     for k in request.args.keys()}
        args = {k.lower(): request.args.get(k)
                for k in request.args.keys()}

        virkning_fra = args.get('virkningfra', None)
        virkning_til = args.get('virkningtil', None)
        registreret_fra = args.get('registreretfra', None)
        registreret_til = args.get('registrerettil', None)

        uuid_param = list_args.get('uuid', None)
        if uuid_param is None:
            # Assume the search operation
            # Later on, we should support searches which filter on uuids as
            # well
            uuid_param = None

            first_result = args.get('foersteresultat', None)
            if first_result is not None:
                first_result = int(first_result)
            max_results = args.get('maximalantalresultater', None)
            if max_results is not None:
                max_results = int(max_results)

            any_attr_value_arr = list_args.get('vilkaarligattr', None)
            any_rel_uuid_arr = list_args.get('vilkaarligrel', None)
            life_cycle_code = args.get('livscykluskode', None)
            user_ref = args.get('brugerref', None)
            note = args.get('notetekst', None)

            # Fill out a registration object based on the query arguments
            registration = {}
            for f in list_args:
                attr = registration.setdefault('attributter', {})
                for attr_name in get_attribute_names(cls.__name__):
                    if f in get_attribute_fields(attr_name):
                        for attr_value in list_args[f]:
                            attr_period = {'virkning': None, f: attr_value}
                            attr.setdefault(attr_name, []).append(attr_period)

                state = registration.setdefault('tilstande', {})
                for state_name in get_state_names(cls.__name__):
                    state_field_name = get_state_field(cls.__name__,
                                                       state_name)

                    state_periods = state.setdefault(state_name, [])
                    if f == state_field_name:
                        for state_value in list_args[f]:
                            state_periods.append({
                                state_field_name: state_value,
                                'virkning': None
                            })

                relation = registration.setdefault('relationer', {})
                if f in get_relation_names(cls.__name__):
                    relation[f] = []
                    # Support multiple relation references at a time
                    for rel in list_args[f]:
                        relation[f].append({
                            'uuid': rel,
                            'virkning': None
                        })

            results = db.search_objects(cls.__name__,
                                        uuid_param,
                                        registration,
                                        virkning_fra, virkning_til,
                                        registreret_fra, registreret_til,
                                        life_cycle_code,
                                        user_ref, note,
                                        any_attr_value_arr,
                                        any_rel_uuid_arr, first_result,
                                        max_results)

        else:
            uuid_param = list_args.get('uuid', None)
            results = db.list_objects(cls.__name__, uuid_param, virkning_fra,
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

        object_list = db.list_objects(cls.__name__, [uuid], None, None,
                                      None, None)
        object = object_list[0]
        return jsonify({uuid: object})

    @classmethod
    def put_object(cls, uuid):
        """
        UPDATE, IMPORT or PASSIVIZE an  object.
        """
        if not request.json:
            return jsonify({'uuid': None}), 400
        # Get most common parameters if available.
        note = request.json.get("note", "")
        attributes = request.json.get("attributter", {})
        states = request.json.get("tilstande", {})
        relations = request.json.get("relationer", {})

        if not db.object_exists(cls.__name__, uuid):
            # Do import.
            result = db.create_or_import_object(cls.__name__, note, attributes,
                                                states, relations, uuid)
            # TODO: When connected to DB, use result properly.
            return jsonify({'uuid': uuid}), 200
        else:
            "Edit or passivate."
            if (request.json.get('livscyklus', '').lower() == 'passiv'):
                # Passivate
                db.passivate_object(
                    cls.__name__, note, uuid
                )
                return jsonify({'uuid': uuid}), 200
            else:
                # Edit/change
                result = db.update_object(cls.__name__, note, attributes,
                                          states, relations, uuid)
                return jsonify({'uuid': uuid}), 200
        return j(u"Forkerte parametre!"), 405

    @classmethod
    def delete_object(cls, uuid):
        # Delete facet
        #import pdb; pdb.set_trace()
        note = request.json.get("Note", "")
        class_name = cls.__name__
        result = db.delete_object(class_name, note, uuid)

        return jsonify({'uuid': uuid}), 200

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
