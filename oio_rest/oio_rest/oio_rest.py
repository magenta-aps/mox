# encoding: utf-8
"""Superclasses for OIO objects and object hierarchies."""
import json
import datetime

import dateutil
from flask import jsonify, request
from custom_exceptions import BadRequestException, NotFoundException
from custom_exceptions import GoneException

from werkzeug.datastructures import ImmutableOrderedMultiDict

import db
from db_helpers import get_valid_search_parameters, TEMPORALITY_PARAMS
import db_structure
from utils.build_registration import build_registration, to_lower_param

# Just a helper during debug
from authentication import requires_auth


def j(t):
    return jsonify(output=t)


def typed_get(d, field, default):
    v = d.get(field, default)
    t = type(default)

    if v is None:
        return default

    # special case strings
    if t is str or t is unicode:
        t = basestring

    if not isinstance(v, t):
        raise BadRequestException('expected %s for %r, found %s: %s' %
                                  (t.__name__, field, type(v).__name__,
                                   json.dumps(v)))

    return v


def get_virkning_dates(args):
    virkning_fra = args.get('virkningfra')
    virkning_til = args.get('virkningtil')
    virkningstid = args.get('virkningstid')

    if virkningstid:
        if virkning_fra or virkning_til:
            raise BadRequestException("'virkningfra'/'virkningtil' conflict "
                                      "with 'virkningstid'")
        # Timespan has to be non-zero length of time, so we add one
        # microsecond
        dt = dateutil.parser.isoparse(virkningstid)
        virkning_fra = dt
        virkning_til = dt + datetime.timedelta(microseconds=1)
    else:
        if virkning_fra is None and virkning_til is None:
            # TODO: Use the equivalent of TSTZRANGE(current_timestamp,
            # current_timestamp,'[]') if possible
            virkning_fra = datetime.datetime.now()
            virkning_til = virkning_fra + datetime.timedelta(
                microseconds=1)
    return virkning_fra, virkning_til


def get_registreret_dates(args):
    registreret_fra = args.get('registreretfra')
    registreret_til = args.get('registrerettil')
    registreringstid = args.get('registreringstid')

    if registreringstid:
        if registreret_fra or registreret_til:
            raise BadRequestException("'registreretfra'/'registrerettil' "
                                      "conflict with 'registreringstid'")
        else:
            # Timespan has to be non-zero length of time, so we add one
            # microsecond
            dt = dateutil.parser.isoparse(registreringstid)
            registreret_fra = dt
            registreret_til = dt + datetime.timedelta(microseconds=1)
    return registreret_fra, registreret_til


class ArgumentDict(ImmutableOrderedMultiDict):
    '''
    A Werkzeug multi dict that maintains the order, and maps alias
    arguments.
    '''

    PARAM_ALIASES = {
        'bvn': 'brugervendtnoegle',
    }

    @classmethod
    def _process_item(cls, (key, value)):
        key = to_lower_param(key)

        return (cls.PARAM_ALIASES.get(key, key), value)

    def __init__(self, mapping):
        # this code assumes that a) we always get a mapping and b)
        # that mapping is specified as list of two-tuples -- which
        # happens to be the case when contructing the dictionary from
        # query arguments
        super(ArgumentDict, self).__init__(
            map(self._process_item, mapping)
        )


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

        hierarchy = cls._name.lower()
        classes_url = u"{0}/{1}/{2}".format(base_url, hierarchy, u"classes")

        def get_classes():
            structure = db_structure.REAL_DB_STRUCTURE
            clsnms = [c.__name__.lower() for c in cls._classes]
            hierarchy_dict = {c: structure[c] for c in clsnms}
            return jsonify(hierarchy_dict)

        flask.add_url_rule(
            classes_url, u'_'.join([hierarchy, 'classes']),
            get_classes, methods=['GET']
        )


class OIORestObject(object):
    """
    Implement an OIO object - manage access to database layer for this object.

    This class is intended to be subclassed, but not to be initialized.
    """

    # The name of the current service. This is set by the create_api() method.
    service_name = None

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
    @requires_auth
    def create_object(cls):
        """
        CREATE object, generate new UUID.
        """
        cls.verify_args()

        input = cls.get_json()
        if not input:
            return jsonify({'uuid': None}), 400

        note = typed_get(input, "note", "")
        registration = cls.gather_registration(input)
        uuid = db.create_or_import_object(cls.__name__, note, registration)
        # Pass log info on request object.
        request.api_operation = "Opret"
        request.uuid = uuid
        return jsonify({'uuid': uuid}), 201

    @classmethod
    def _get_args(cls, as_lists=False):
        """
        Convert arguments to lowercase, optionally getting them as lists.
        """
        return {to_lower_param(k): (request.args.get(k) if not as_lists else
                                    request.args.getlist(k))
                for k in request.args}

    @classmethod
    @requires_auth
    def get_objects(cls):
        """
        LIST or SEARCH objects, depending on parameters.
        """
        request.parameter_storage_class = ArgumentDict

        cls.verify_args(*get_valid_search_parameters(cls.__name__))

        # Convert arguments to lowercase, getting them as lists
        list_args = cls._get_args(True)
        args = cls._get_args()
        registreret_fra, registreret_til = get_registreret_dates(args)
        virkning_fra, virkning_til = get_virkning_dates(args)

        uuid_param = list_args.get('uuid', None)

        valid_list_args = TEMPORALITY_PARAMS | {'uuid'}

        # Assume the search operation if other params were specified
        if not valid_list_args.issuperset(args):
            # Only one uuid is supported through the search operation
            if uuid_param is not None and len(uuid_param) > 1:
                raise BadRequestException("Multiple uuid parameters passed "
                                          "to search operation. Only one "
                                          "uuid parameter is supported.")
            uuid_param = args.get('uuid', None)
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
            request.api_operation = "Søg"
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
            request.api_operation = "List"
            results = db.list_objects(cls.__name__, uuid_param, virkning_fra,
                                      virkning_til, registreret_fra,
                                      registreret_til)
        if results is None:
            results = []
        if uuid_param:
            request.uuid = uuid_param
        else:
            request.uuid = ''
        return jsonify({'results': results})

    @classmethod
    @requires_auth
    def get_object(cls, uuid):
        """
        READ an object, return as JSON.
        """
        cls.verify_args(*TEMPORALITY_PARAMS)

        args = cls._get_args()
        registreret_fra, registreret_til = get_registreret_dates(args)

        virkning_fra, virkning_til = get_virkning_dates(args)

        request.api_operation = u'Læs'
        request.uuid = uuid
        object_list = db.list_objects(cls.__name__, [uuid], virkning_fra,
                                      virkning_til, registreret_fra,
                                      registreret_til)
        try:
            object = object_list[0]
        except IndexError:
            # No object found with that ID.
            raise NotFoundException(
                "No {} with ID {} found in service {}".format(
                    cls.__name__, uuid, cls.service_name
                )
            )
        # Raise 410 Gone if object is deleted.
        if object[0]["registreringer"][0][
            "livscykluskode"
        ] == db.Livscyklus.SLETTET.value:
            raise GoneException("This object has been deleted.")
        return jsonify({uuid: object})

    @classmethod
    def gather_registration(cls, input):
        """Return a registration dict from the input dict."""
        attributes = typed_get(input, "attributter", {})
        states = typed_get(input, "tilstande", {})
        relations = typed_get(input, "relationer", {})
        return {"states": states,
                "attributes": attributes,
                "relations": relations}

    @classmethod
    @requires_auth
    def put_object(cls, uuid):
        """
        IMPORT or UPDATE an  object, replacing its contents entirely.
        """
        cls.verify_args()

        input = cls.get_json()
        if not input:
            return jsonify({'uuid': None}), 400
        # Get most common parameters if available.
        note = typed_get(input, "note", "")
        registration = cls.gather_registration(input)
        exists = db.object_exists(cls.__name__, uuid)
        deleted_or_passive = False
        if exists:
            livscyklus = db.get_life_cycle_code(cls.__name__, uuid)
            if (
                livscyklus == db.Livscyklus.PASSIVERET.value or
                livscyklus == db.Livscyklus.SLETTET.value
            ):
                deleted_or_passive = True

        request.uuid = uuid

        if not exists:
            # Do import.
            request.api_operation = "Import"
            db.create_or_import_object(cls.__name__, note, registration, uuid)
            return jsonify({'uuid': uuid}), 200
        elif deleted_or_passive:
            # Import.
            request.api_operation = "Import"
            db.update_object(cls.__name__, note, registration,
                             uuid=uuid,
                             life_cycle_code=db.Livscyklus.IMPORTERET.value)
            return jsonify({'uuid': uuid}), 200
        else:
            # Edit.
            request.api_operation = "Ret"
            db.create_or_import_object(cls.__name__, note, registration, uuid)

            return jsonify({'uuid': uuid}), 200

    @classmethod
    @requires_auth
    def patch_object(cls, uuid):
        """UPDATE or PASSIVIZE this object."""

        # If the object doesn't exist, we can't patch it.
        if not db.object_exists(cls.__name__, uuid):
            raise NotFoundException(
                "No {} with ID {} found in service {}".format(
                    cls.__name__, uuid, cls.service_name
                )
            )

        input = cls.get_json()
        if not input:
            return jsonify({'uuid': None}), 400
        # Get most common parameters if available.
        note = typed_get(input, "note", "")
        registration = cls.gather_registration(input)

        if typed_get(input, 'livscyklus', '').lower() == 'passiv':
            # Passivate
            request.api_operation = "Passiver"
            registration = cls.gather_registration({})
            db.passivate_object(
                cls.__name__, note, registration, uuid
            )
            return jsonify({'uuid': uuid}), 200
        else:
            # Edit/change
            request.api_operation = "Ret"
            db.update_object(cls.__name__, note, registration,
                             uuid)
            return jsonify({'uuid': uuid}), 200

    @classmethod
    @requires_auth
    def delete_object(cls, uuid):

        """Logically delete this object."""
        cls.verify_args()

        input = cls.get_json() or {}
        note = typed_get(input, "note", "")
        class_name = cls.__name__
        # Gather a blank registration
        registration = cls.gather_registration({})
        request.api_operation = "Slet"
        request.uuid = uuid
        db.delete_object(class_name, registration, note, uuid)

        return jsonify({'uuid': uuid}), 202

    @classmethod
    def get_fields(cls):
        cls.verify_args()

        """Set up API with correct database access functions."""
        structure = db_structure.REAL_DB_STRUCTURE
        class_key = cls.__name__.lower()
        # TODO: Perform some transformations to improve readability.
        class_dict = structure[class_key]
        return jsonify(class_dict)

    @classmethod
    def create_api(cls, hierarchy, flask, base_url):
        """Set up API with correct database access functions."""
        cls.service_name = hierarchy
        hierarchy = hierarchy.lower()
        class_name = cls.__name__.lower()
        class_url = u"{0}/{1}/{2}".format(base_url,
                                          hierarchy,
                                          class_name)
        cls_fields_url = u"{0}/{1}".format(class_url, u"fields")
        uuid_regex = (
            "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}" +
            "-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}"
        )
        object_url = u'{0}/<regex("{1}"):uuid>'.format(
            class_url,
            uuid_regex
        )

        def get_classes_for_hierarchy():
            return cls.get_classes(hierarchy)

        flask.add_url_rule(class_url, u'_'.join([cls.__name__, 'get_objects']),
                           cls.get_objects, methods=['GET'],
                           strict_slashes=False)

        flask.add_url_rule(object_url, u'_'.join([cls.__name__, 'get_object']),
                           cls.get_object, methods=['GET'])

        flask.add_url_rule(object_url, u'_'.join([cls.__name__, 'put_object']),
                           cls.put_object, methods=['PUT'])
        flask.add_url_rule(object_url,
                           u'_'.join([cls.__name__, 'patch_object']),
                           cls.patch_object, methods=['PATCH'])
        flask.add_url_rule(
            class_url, u'_'.join([cls.__name__, 'create_object']),
            cls.create_object, methods=['POST']
        )

        flask.add_url_rule(
            object_url, u'_'.join([cls.__name__, 'delete_object']),
            cls.delete_object, methods=['DELETE']
        )

        # Structure URLs
        flask.add_url_rule(
            cls_fields_url, u'_'.join([cls.__name__, 'fields']),
            cls.get_fields, methods=['GET']
        )

    # Templates which may be overridden on subclass.
    # Templates may only be overridden on subclass if they are explicitly
    # listed here.
    RELATIONS_TEMPLATE = 'relations_array.sql'

    @classmethod
    def verify_args(cls, *allowed):
        req_args = cls._get_args()
        difference = set(req_args).difference(allowed)
        if difference:
            arg_string = ', '.join(difference)
            raise BadRequestException('Unsupported argument(s): {}'
                                      .format(arg_string))
