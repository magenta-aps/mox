from datetime import datetime
import json
from urlparse import urlparse
from flask import jsonify, request
from utils import BadRequestException

import db
from db_helpers import get_attribute_names, get_attribute_fields
from db_helpers import get_state_names, get_relation_names, get_state_field

from utils import build_registration


# Just a helper during debug
from authentication import requires_auth


def j(t):
    return jsonify(output=t)

class Registration(object):
    def __init__(self, oio_class, states, attributes, relations):
        self.oio_class = oio_class
        self.states = states
        self.attributes = attributes
        self.relations = relations

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
    def get_json(cls):
        """
        Return the JSON input from the request.
        The JSON input typically comes from the body of the request with
        Content-Type: application/json. However, for POST/PUT operations
        involving multipart/form-data, the JSON input is expected to be
        contained in a form field called 'json'. This method handles this in a
        consistent way.
        """
        if request.json:
            return request.json
        else:
            data = request.form.get('json', None)
            if data is not None:
                try:
                    if request.charset is not None:
                        return json.loads(data, encoding=request.charset)
                    else:
                        return json.loads(data)
                except ValueError as e:
                    request.on_json_loading_failed(e)
            else:
                return None

    @classmethod
    def _get_file_storage_for_content_url(cls, url):
        """
        Return a FileStorage object for the form field specified by the URL.

        The URL uses the scheme 'field', and its path points to a form field
        which contains the uploaded file. For example, for a URL of 'field:f1',
        this method would return the FileStorage object for the file
        contained in form field 'f1'.
        """
        o = urlparse(url)
        if o.scheme == 'field':
            field_name = o.path
            file_obj = request.files.get(field_name, None)
            if file_obj is None:
                raise BadRequestException(
                    ('The content URL "%s" referenced the field "%s", but it '
                     'was not present in the request.') % (url, o.path)
                )
            return file_obj
        else:
            raise BadRequestException(
                'The content field referenced an unsupported '
                'scheme or was invalid. The URLs must be of the'
                'form: field:<form-field>, where <form-field> '
                'is the name of the field in the '
                'multipart/form-data-encoded request that '
                'contains the file binary data.'
            )

    @classmethod
    @requires_auth
    def create_object(cls):
        """
        CREATE object, generate new UUID.
        """
        input = cls.get_json()
        if not input:
            return jsonify({'uuid': None}), 400

        note = input.get("note", "")
        registration = cls.gather_registration(input)
        uuid = db.create_or_import_object(cls.__name__, note, registration)
        return jsonify({'uuid': uuid}), 201

    @classmethod
    @requires_auth
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
            registration = build_registration(cls.__name__, list_args)
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
    @requires_auth
    def get_object(cls, uuid):
        """
        READ a facet, return as JSON.
        """

        object_list = db.list_objects(cls.__name__, [uuid], None, None,
                                      None, None)
        object = object_list[0]
        return jsonify({uuid: object})

    @classmethod
    def gather_registration(cls, input):
        """Return a registration dict from the input dict."""
        attributes = input.get("attributter", {})
        states = input.get("tilstande", {})
        relations = input.get("relationer", {})
        return {"states": states,
                "attributes": attributes,
                "relations": relations}

    @classmethod
    @requires_auth
    def put_object(cls, uuid):
        """
        UPDATE, IMPORT or PASSIVIZE an  object.
        """
        input = cls.get_json()
        if not input:
            return jsonify({'uuid': None}), 400
        # Get most common parameters if available.
        note = input.get("note", "")

        registration = cls.gather_registration(input)

        if not db.object_exists(cls.__name__, uuid):
            # Do import.
            result = db.create_or_import_object(cls.__name__, note,
                                                registration, uuid)
            # TODO: When connected to DB, use result properly.
            return jsonify({'uuid': uuid}), 200
        else:
            "Edit or passivate."
            if (input.get('livscyklus', '').lower() == 'passiv'):
                # Passivate
                db.passivate_object(
                    cls.__name__, note, uuid
                )
                return jsonify({'uuid': uuid}), 200
            else:
                # Edit/change
                result = db.update_object(cls.__name__, note, registration, uuid)
                return jsonify({'uuid': uuid}), 200
        return j(u"Forkerte parametre!"), 405

    @classmethod
    @requires_auth
    def delete_object(cls, uuid):
        # Delete facet
        input = cls.get_json()
        if not input:
            return jsonify({'uuid': None}), 400
        note = input.get("Note", "")
        class_name = cls.__name__
        # Gather a blank registration
        registration = cls.gather_registration({})
        result = db.delete_object(class_name, registration, note, uuid)

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

    # Templates which may be overridden on subclass.
    # Templates may only be overridden on subclass if they are explicitly
    # listed here.
    RELATIONS_TEMPLATE = 'relations_array.sql'
