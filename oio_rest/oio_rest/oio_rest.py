# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


# encoding: utf-8
"""Superclasses for OIO objects and object hierarchies."""
import json
import datetime

import dateutil
import jsonschema
from flask import jsonify, request

from werkzeug.datastructures import ImmutableOrderedMultiDict

from . import db
from .db import db_helpers
from . import validate
from .utils.build_registration import build_registration, to_lower_param
from .utils.build_registration import split_param
from .custom_exceptions import BadRequestException, NotFoundException
from .custom_exceptions import GoneException

# Just a helper during debug
from .authentication import requires_auth

from . import settings


'''List of parameters allowed for all searches.'''
GENERAL_SEARCH_PARAMS = frozenset({
    'brugerref',
    'foersteresultat',
    'livscykluskode',
    'maximalantalresultater',
    'notetekst',
    'uuid',
    'vilkaarligattr',
    'vilkaarligrel',
})

'''List of parameters allowed the apply to temporal operations, i.e.
search and list.

'''
TEMPORALITY_PARAMS = frozenset({
    'registreretfra',
    'registrerettil',
    'registreringstid',
    'virkningfra',
    'virkningtil',
    'virkningstid',
})

'''Some operations take no arguments; this makes it explicit.

'''
NO_PARAMS = frozenset()

'''Aliases that apply to all operations.'''
PARAM_ALIASES = {
    'bvn': 'brugervendtnoegle',
}


def j(t):
    return jsonify(output=t)


def typed_get(d, field, default):
    v = d.get(field, default)
    t = type(default)

    if v is None:
        return default

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

    @classmethod
    def _process_item(cls, item):
        (key, value) = item
        key = to_lower_param(key)

        return (PARAM_ALIASES.get(key, key), value)

    def __init__(self, mapping):
        # this code assumes that a) we always get a mapping and b)
        # that mapping is specified as list of two-tuples -- which
        # happens to be the case when contructing the dictionary from
        # query arguments
        super(ArgumentDict, self).__init__(
            list(map(self._process_item, mapping))
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
        classes_url = "{0}/{1}/{2}".format(base_url, hierarchy, "classes")

        def get_classes():
            """Return the classes including their fields under this service.

            Part of the self-documentation of the API.

            .. :quickref: Lists all classed with fields an service have.

            :statuscode 200: No error.

            """
            structure = settings.REAL_DB_STRUCTURE
            clsnms = [c.__name__.lower() for c in cls._classes]
            hierarchy_dict = {c: structure[c] for c in clsnms}
            return jsonify(hierarchy_dict)

        flask.add_url_rule(
            classes_url, '_'.join([hierarchy, 'classes']),
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
        """A :ref:`CreateOperation` that creates a new object from the JSON payload. It returns
        a newly generated UUID for the created object.

        The data can be supplied directly in the request if the header
        :http:header:`Content-Type`: ``application/json`` is set.

        Alternatively the the data can be supplied as form-data in the ``json``-field
        with the header :http:header:`Content-Type`: ``multipart/form-data``.

        .. :quickref: :ref:`CreateOperation`


        **Example request** for :http:post:`/organisation/organisationenhed`:

        .. code-block:: http

            POST /organisation/organisationenhed HTTP/1.1
            Content-Type: application/json
            Host: example.com

            {"attributter": {
                 "organisationenhedegenskaber": [{
                         "brugervendtnoegle": "copenhagen",
                         "enhedsnavn": "Copenhagen",
                         "virkning": {
                             "from": "2017-01-01",
                             "to": "2019-03-14"
                         }}]},
             "relationer": {
                 "overordnet": [{
                         "uuid": "6ff6cf06-fa47-4bc8-8a0e-7b21763bc30a",
                         "virkning": {
                             "from": "2017-01-01",
                             "to": "2019-03-14"
                         }}],
                 "tilhoerer": [{
                         "uuid": "6135c99b-f0fe-4c46-bb50-585b4559b48a",
                         "virkning": {
                             "from": "2017-01-01",
                             "to": "2019-03-14"
                         }}]},
             "tilstande": {
                 "organisationenhedgyldighed": [{
                         "gyldighed": "Aktiv",
                         "virkning": {
                             "from": "2017-01-01",
                             "to": "2019-03-14"
                         }}]}}

        **Example response** for :http:post:`/organisation/organisationenhed`:

        .. code-block:: http

            HTTP/1.0 201 CREATED
            Content-Length: 48
            Content-Type: application/json
            Date: Mon, 21 Jan 2019 09:12:00 GMT
            Server: Werkzeug/0.14.1 Python/3.5.2

            {
                "uuid": "14b2abd4-ae3c-4a0f-b530-7a93443d729d"
            }

        :reqheader Content-Type: ``application/json`` or ``multipart/form-data``

        :statuscode 201: Object was created.
        :statuscode 400: Malformed JSON or other bad request.

        """

        cls.verify_args()

        input = cls.get_json()
        if not input:
            return jsonify({'uuid': None}), 400

        # Validate JSON input
        try:
            validate.validate(input)
        except jsonschema.exceptions.ValidationError as e:
            return jsonify({'message': e.message}), 400

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
        """A :ref:`ListOperation` or :ref:`SearchOperation` depending on parameters.

        With any the of ``uuid``, ``virking*`` and ``registeret`` parameters, it is a
        :ref:`ListOperation` and will return one or more whole JSON-objects. Given any
        other parameters the operation is a :ref:`SearchOperation` and will only return
        a list of UUIDs to the objects.

        Default is to return the object(s) as it is currently seen, but can optionally
        be constrained by ``virking*`` :ref:`valid time<Valid time>` and/or
        ``registrering*`` :ref:`transaction time<transaction time>` to give an older
        view.

        .. :quickref: :ref:`ListOperation` or :ref:`SearchOperation`

        **List example request** for :http:get:`/organisation/organisationenhed`:

        .. code-block:: http

            GET /organisation/organisationenhed?uuid=74054d5b-54fc-4c9e-86ef-790fa6935afb&uuid=ccfd6874-09f5-4dec-8d39-781f614bb8a7 HTTP/1.1
            Accept: */*
            Host: example.com

        **List example response** for :http:get:`/organisation/organisationenhed`:

        .. code-block:: http

            HTTP/1.0 200 OK
            Content-Length: 2150
            Content-Type: application/json
            Date: Thu, 17 Jan 2019 14:49:31 GMT
            Server: Werkzeug/0.14.1 Python/3.5.2

            {"results": [[{
                         "id": "74054d5b-54fc-4c9e-86ef-790fa6935afb",
                         "registreringer": [{
                                 "attributter": {
                                     "organisationenhedegenskaber": [{
                                             "brugervendtnoegle": "copenhagen",
                                             "enhedsnavn": "Copenhagen",
                                             "virkning": {
                                                 "from": "2017-01-01 00:00:00+00",
                                                 "from_included": true,
                                                 "to": "2019-03-14 00:00:00+00",
                                                 "to_included": false
                                             }}]},
                                 "brugerref": "42c432e8-9c4a-11e6-9f62-873cf34a735f",
                                 "fratidspunkt": {
                                     "graenseindikator": true,
                                     "tidsstempeldatotid": "2019-01-11T10:10:59.430647+00:00"
                                 },
                                 "livscykluskode": "Opstaaet",
                                 "relationer": {
                                     "overordnet": [{
                                             "uuid": "66e8a55a-8c61-4d33-b244-574c09ef41f7",
                                             "virkning": {
                                                 "from": "2017-01-01 00:00:00+00",
                                                 "from_included": true,
                                                 "to": "2019-03-14 00:00:00+00",
                                                 "to_included": false
                                             }}],
                                     "tilhoerer": [{
                                             "uuid": "66e8a55a-8c61-4d33-b244-574c09ef41f7",
                                             "virkning": {
                                                 "from": "2017-01-01 00:00:00+00",
                                                 "from_included": true,
                                                 "to": "2019-03-14 00:00:00+00",
                                                 "to_included": false
                                             }}]},
                                 "tilstande": {
                                     "organisationenhedgyldighed": [{
                                             "gyldighed": "Aktiv",
                                             "virkning": {
                                                 "from": "2017-01-01 00:00:00+00",
                                                 "from_included": true,
                                                 "to": "2019-03-14 00:00:00+00",
                                                 "to_included": false
                                             }}]},
                                 "tiltidspunkt": {
                                     "tidsstempeldatotid": "infinity"
                                 }}]},
                     {
                         "id": "ccfd6874-09f5-4dec-8d39-781f614bb8a7",
                         "registreringer": [{
                                 "attributter": {
                                     "organisationenhedegenskaber": [{
                                             "brugervendtnoegle": "aarhus",
                                             "enhedsnavn": "Aarhus",
                                             "virkning": {
                                                 "from": "2018-01-01 00:00:00+00",
                                                 "from_included": true,
                                                 "to": "2019-09-01 00:00:00+00",
                                                 "to_included": false
                                             }}]},
                                 "brugerref": "42c432e8-9c4a-11e6-9f62-873cf34a735f",
                                 "fratidspunkt": {
                                     "graenseindikator": true,
                                     "tidsstempeldatotid": "2019-01-11T10:10:59.688454+00:00"
                                 },
                                 "livscykluskode": "Rettet",
                                 "relationer": {
                                     "overordnet": [{
                                             "uuid": "66e8a55a-8c61-4d33-b244-574c09ef41f7",
                                             "virkning": {
                                                 "from": "2018-01-01 00:00:00+00",
                                                 "from_included": true,
                                                 "to": "2019-09-01 00:00:00+00",
                                                 "to_included": false
                                             }}],
                                     "tilhoerer": [{
                                             "uuid": "66e8a55a-8c61-4d33-b244-574c09ef41f7",
                                             "virkning": {
                                                 "from": "2018-01-01 00:00:00+00",
                                                 "from_included": true,
                                                 "to": "2019-09-01 00:00:00+00",
                                                 "to_included": false
                                             }}]},
                                 "tilstande": {
                                     "organisationenhedgyldighed": [{
                                             "gyldighed": "Aktiv",
                                             "virkning": {
                                                 "from": "2018-01-01 00:00:00+00",
                                                 "from_included": true,
                                                 "to": "2019-09-01 00:00:00+00",
                                                 "to_included": false
                                             }}]},
                                 "tiltidspunkt": {
                                     "tidsstempeldatotid": "infinity"
                                 }}]}]]}


        **Search example request** for :http:get:`/organisation/organisationenhed`:

        .. code-block:: http

            GET /organisation/organisationenhed?overordnet=66e8a55a-8c61-4d33-b244-574c09ef41f7 HTTP/1.1
            Accept: */*
            Host: example.com

        **Search example response** for :http:get:`/organisation/organisationenhed`:

        .. code-block:: http


            HTTP/1.0 200 OK
            Content-Length: 94
            Content-Type: application/json
            Date: Thu, 17 Jan 2019 15:02:39 GMT
            Server: Werkzeug/0.14.1 Python/3.5.2

            {"results": [[
                     "74054d5b-54fc-4c9e-86ef-790fa6935afb",
                     "ccfd6874-09f5-4dec-8d39-781f614bb8a7"
                 ]]}

        :query uuid uuid: The UUID of the object to receive. Allowed multiple times in :ref:`ListOperation`. Allowed once in :ref:`SearchOperation`.

        :query string brugervendtnoegle / bvn: Match text in the ``brugervendtnoegle``-field. Not allowed in List.
        :query string vilkaarligattr: Match text values of *any* ``attributter``-field. Not allowed in List.
        :query uuid vilkaarligrel: Match values of *any* ``relationer``. Not allowed in List.
        :query enum livscykluskode: Matches the ``livscykluskode``-field. Can be one of ``Opstaaet``, ``Importeret``, ``Passiveret``, ``Slettet`` or ``Rettet``. Not allowed in List.

        :query uuid brugerref: Match the ``brugerref``-field. The (system) user who changed the object.
        :query string notetekst: Match the ``notetekst``-field in ``virkning``. (Not to be confused with the ``note``-field.) Not allowed in List.

        :query int foersteresultat: The first result in a :ref:`PagedSearchOperation`. Sorts the result by ``brugervendtnoegle``. Not allowed in List.
        :query int maximalantalresultater: The maximal number of results in a :ref:`PagedSearchOperation`. Sorts the result by ``brugervendtnoegle``. Not allowed in List.

        :query datetime registreretFra: :ref:`Transaction time` 'from' timestamp.
        :query datetime registreretTil: Transaction time 'to' timestamp.
        :query datetime registreringstid: Transaction time 'snapshot' timestamp.
        :query datetime virkningFra: :ref:`Valid time` 'from' timestamp.
        :query datetime virkningTil: Valid time 'to' timestamp.
        :query datetime virkningstid: Valid time 'snapshot' timestamp.

        All the ``registeret*`` and ``virkning*`` take a datetime. Input is accepted in
        almost any reasonable format, including ISO 8601, SQL-compatible, traditional
        POSTGRES, and others. The accepted values are the `Date/Time Input from
        PostgreSQL
        <https://www.postgresql.org/docs/9.5/datatype-datetime.html#DATATYPE-DATETIME-INPUT>`_.

        All *string* parameters match case insensitive. They support the wildcard
        operators ``_`` (underscore) to match a single character and ``%`` (percent
        sign) to match zero or more characters. The match is made with `ILIKE from
        PostgresSQL
        <https://www.postgresql.org/docs/9.5/functions-matching.html#FUNCTIONS-LIKE>`_.

        In addition to the above general query parameters, each object also have
        specialized parameters based on its field. The endpoints
        ``/<class>/<object>/fields`` lists the fields which can be used for parameters
        for a :ref:`SearchOperation`.

        :resheader Content-Type: ``application/json``

        :statuscode 200: No error.
        :statuscode 400: The request is malformed.
        :statuscode 404: No object of a given class with that UUID.
        :statuscode 410: The object has been :ref:`deleted <DeleteOperation>`.

        """
        request.parameter_storage_class = ArgumentDict

        cls.verify_args(search=True, temporality=True)

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
        A :ref:`ReadOperation`. Return the whole object as a JSON-object. Default is to
        return the object as it is currently seen, but can optionally be constrained by
        ``virking*`` :ref:`valid time<Valid time>` and/or ``registrering*``
        :ref:`transaction time<transaction time>` to give an older view.

        .. :quickref: :ref:`ReadOperation`

        **Example request** for :http:get:`/organisation/organisation/(regex:uuid)`:

        .. code-block:: http

            GET /organisation/organisation/5729e3f9-2993-4492-a56f-0ef7efc83111 HTTP/1.1
            Accept: */*
            Host: example.com

        **Example response** for :http:get:`/organisation/organisation/(regex:uuid)`:

        .. code-block:: http

            HTTP/1.0 200 OK
            Content-Length: 744
            Content-Type: application/json
            Date: Tue, 15 Jan 2019 12:27:16 GMT
            Server: Werkzeug/0.14.1 Python/3.5.2

            {"5729e3f9-2993-4492-a56f-0ef7efc83111": [{
                     "id": "5729e3f9-2993-4492-a56f-0ef7efc83111",
                     "registreringer": [{
                             "attributter": {
                                 "organisationegenskaber": [{
                                         "brugervendtnoegle": "magenta-aps",
                                         "organisationsnavn": "Magenta ApS",
                                         "virkning": {
                                             "from": "2017-01-01 00:00:00+00",
                                             "from_included": true,
                                             "to": "2019-03-14 00:00:00+00",
                                             "to_included": false
                                         }}]},
                             "brugerref": "42c432e8-9c4a-11e6-9f62-873cf34a735f",
                             "fratidspunkt": {
                                 "graenseindikator": true,
                                 "tidsstempeldatotid": "2019-01-15T10:43:58.122764+00:00"
                             },
                             "livscykluskode": "Importeret",
                             "tilstande": {
                                 "organisationgyldighed": [{
                                         "gyldighed": "Aktiv",
                                         "virkning": {
                                             "from": "2017-01-01 00:00:00+00",
                                             "from_included": true,
                                             "to": "2019-03-14 00:00:00+00",
                                             "to_included": false
                                         }}]},
                             "tiltidspunkt": {
                                 "tidsstempeldatotid": "infinity"
                             }}]}]}



        :query datetime registreretFra: :ref:`Transaction time` 'from' timestamp.
        :query datetime registreretTil: Transaction time 'to' timestamp.
        :query datetime registreringstid: Transaction time 'snapshot' timestamp.
        :query datetime virkningFra: :ref:`Valid time` 'from' timestamp.
        :query datetime virkningTil: Valid time 'to' timestamp.
        :query datetime virkningstid: Valid time 'snapshot' timestamp.

        All the ``registeret*`` and ``virkning*`` take a datetime. Input is accepted in
        almost any reasonable format, including ISO 8601, SQL-compatible, traditional
        POSTGRES, and others. The accepted values are the `Date/Time Input from
        PostgreSQL
        <https://www.postgresql.org/docs/9.5/datatype-datetime.html#DATATYPE-DATETIME-INPUT>`_.

        :resheader Content-Type: ``application/json``

        :statuscode 200: No error.
        :statuscode 400: The request is malformed.
        :statuscode 404: No object of a given class with that UUID.
        :statuscode 410: The object has been :ref:`deleted <DeleteOperation>`.

        """
        cls.verify_args(temporality=True)

        args = cls._get_args()
        registreret_fra, registreret_til = get_registreret_dates(args)

        virkning_fra, virkning_til = get_virkning_dates(args)

        request.api_operation = 'Læs'
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
        filtered_relations = {
            key: val for key, val in relations.items() if val
        }

        return {"states": states,
                "attributes": attributes,
                "relations": filtered_relations}

    @classmethod
    @requires_auth
    def put_object(cls, uuid):
        """A :ref:`ImportOperation` that creates or overwrites a object from the JSON payload.
        It returns the UUID for the object.

        If there a no object with the UUID or the object with that UUID have been
        :ref:`deleted <DeleteOperation>` or :ref:`passivated <PassivateOperation>`, it
        creates a new object at the specified UUID. It sets ``livscykluskode:
        "Importeret"``.

        If a object with the UUID exist it completely overwrite the object. Including
        all ``virkning``-periods. It sets ``livscykluskode: "Rettet"``.

        .. :quickref: :ref:`ImportOperation`

        **Example request** for :http:put:`/organisation/organisationenhed/(regex:uuid)`:

        .. code-block:: http

            PUT /organisation/organisationenhed/841190a7-0e70-468a-bd63-eb11ed615337 HTTP/1.1
            Content-Type: application/json
            Host: example.com

            {"attributter": {
                 "organisationenhedegenskaber": [{
                         "brugervendtnoegle": "copenhagen",
                         "enhedsnavn": "Copenhagen",
                         "virkning": {
                             "from": "2017-01-01",
                             "to": "2019-03-14"
                         }}]},
             "relationer": {
                 "overordnet": [{
                         "uuid": "6ff6cf06-fa47-4bc8-8a0e-7b21763bc30a",
                         "virkning": {
                             "from": "2017-01-01",
                             "to": "2019-03-14"
                         }}],
                 "tilhoerer": [{
                         "uuid": "6135c99b-f0fe-4c46-bb50-585b4559b48a",
                         "virkning": {
                             "from": "2017-01-01",
                             "to": "2019-03-14"
                         }}]},
             "tilstande": {
                 "organisationenhedgyldighed": [{
                         "gyldighed": "Aktiv",
                         "virkning": {
                             "from": "2017-01-01",
                             "to": "2019-03-14"
                         }}]}}


        **Example response** for :http:put:`/organisation/organisationenhed/(regex:uuid)`:

        .. code-block:: http

            HTTP/1.0 200 OK
            Content-Length: 48
            Content-Type: application/json
            Date: Mon, 21 Jan 2019 10:17:19 GMT
            Server: Werkzeug/0.14.1 Python/3.5.2

            {
                "uuid": "841190a7-0e70-468a-bd63-eb11ed615337"
            }


        :reqheader Content-Type: ``application/json``

        :statuscode 200: Object was created or overwritten.
        :statuscode 400: Malformed JSON or other bad request.
        """
        cls.verify_args()

        input = cls.get_json()
        if not input:
            return jsonify({'uuid': None}), 400

        # Validate JSON input
        try:
            validate.validate(input)
        except jsonschema.exceptions.ValidationError as e:
            return jsonify({'message': e.message}), 400

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
        """An :ref:`UpdateOperation` or :ref:`PassivateOperation`. Apply the JSON payload as a
        change to the object. Return the UUID of the object.

        If ``livscyklus: "Passiv"`` is set it is a :ref:`PassivateOperation`. The object
        will be passivated and afterwards not show up in searches and listings.

        A lot of examples of how the changes are applied are described on
        :ref:`AdvUpdateOperation`.

        .. :quickref: :ref:`UpdateOperation` or :ref:`PassivateOperation`

        **Example request** for :http:patch:`/organisation/organisationenhed/(regex:uuid)`:

        .. code-block:: http

            PATCH /organisation/organisationenhed/5fc97a7c-70df-4e97-82eb-64dc0a0f5746 HTTP/1.1
            Content-Type: application/json
            Host: example.com

            {"relationer": {
                 "adresser": [{
                         "urn": "dawa:0a3f50c4-379f-32b8-e044-0003ba298018",
                         "virkning": {
                             "from": "2018-01-01",
                             "to": "2019-09-01"
                         }}]}}

        **Example response** for :http:patch:`/organisation/organisationenhed/(regex:uuid)`:

        .. code-block:: http

            HTTP/1.0 200 OK
            Content-Length: 48
            Content-Type: application/json
            Date: Mon, 21 Jan 2019 12:40:36 GMT
            Server: Werkzeug/0.14.1 Python/3.5.2

            {
                "uuid": "5fc97a7c-70df-4e97-82eb-64dc0a0f5746"
            }

        :reqheader Content-Type: ``application/json``

        :statuscode 200: Object was updated or passivated.
        :statuscode 400: Malformed JSON or other bad request.
        :statuscode 404: The object was not found.
        """

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
        """A :ref:`DeleteOperation`. Delete the object and return the UUID.

        .. :quickref: :ref:`DeleteOperation`

        **Example request** for :http:delete:`/organisation/organisationenhed/(regex:uuid)`:

        .. code-block:: http

            DELETE /organisation/organisationenhed/5fc97a7c-70df-4e97-82eb-64dc0a0f5746 HTTP/1.1
            Host: example.com


        **Example response** for :http:delete:`/organisation/organisationenhed/(regex:uuid)`:

        .. code-block:: http

            HTTP/1.0 202 ACCEPTED
            Content-Length: 48
            Content-Type: application/json
            Date: Mon, 21 Jan 2019 16:47:00 GMT
            Server: Werkzeug/0.14.1 Python/3.5.2

            {
                "uuid": "5fc97a7c-70df-4e97-82eb-64dc0a0f5746"
            }


        :statuscode 202: Object was deleted.
        :statuscode 400: Malformed JSON or other bad request.
        :statuscode 404: No object of a given class with that UUID.
        """

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
        """Return a list of all fields a given object have.

         Part of the self-documentation of the API.

        .. :quickref: Lists all fields an object have.

        :statuscode 200: No error.

        """
        cls.verify_args()

        """Set up API with correct database access functions."""
        structure = settings.REAL_DB_STRUCTURE
        class_key = cls.__name__.lower()
        # TODO: Perform some transformations to improve readability.
        class_dict = structure[class_key]
        return jsonify(class_dict)

    @classmethod
    def get_schema(cls):
        cls.verify_args()
        return jsonify(validate.SCHEMA[cls.__name__.lower()])

    @classmethod
    def create_api(cls, hierarchy, flask, base_url):
        """Set up API with correct database access functions."""
        cls.service_name = hierarchy
        hierarchy = hierarchy.lower()
        class_name = cls.__name__.lower()
        class_url = "{0}/{1}/{2}".format(base_url,
                                         hierarchy,
                                         class_name)
        cls_fields_url = "{0}/{1}".format(class_url, "fields")
        uuid_regex = (
            "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}" +
            "-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}"
        )
        object_url = '{0}/<regex("{1}"):uuid>'.format(
            class_url,
            uuid_regex
        )

        flask.add_url_rule(
            class_url,
            '_'.join([cls.__name__, 'get_objects']),
            cls.get_objects,
            methods=['GET'],
        )

        flask.add_url_rule(
            object_url,
            '_'.join([cls.__name__, 'get_object']),
            cls.get_object,
            methods=['GET'],
        )

        flask.add_url_rule(
            object_url,
            '_'.join([cls.__name__, 'put_object']),
            cls.put_object,
            methods=['PUT'],
        )

        flask.add_url_rule(
            object_url,
            '_'.join([cls.__name__, 'patch_object']),
            cls.patch_object,
            methods=['PATCH'],
        )

        flask.add_url_rule(
            class_url,
            '_'.join([cls.__name__, 'create_object']),
            cls.create_object,
            methods=['POST'],
        )

        flask.add_url_rule(
            object_url,
            '_'.join([cls.__name__, 'delete_object']),
            cls.delete_object,
            methods=['DELETE'],
        )

        # Structure URLs
        flask.add_url_rule(
            cls_fields_url,
            '_'.join([cls.__name__, 'fields']),
            cls.get_fields,
            methods=['GET'],
        )

        # JSON schemas
        flask.add_url_rule(
            '{}/{}'.format(class_url, 'schema'),
            '_'.join([cls.__name__, 'schema']),
            cls.get_schema,
            methods=['GET'],
        )

    # Templates which may be overridden on subclass.
    # Templates may only be overridden on subclass if they are explicitly
    # listed here.
    RELATIONS_TEMPLATE = 'relations_array.sql'

    @classmethod
    def attribute_names(cls):
        return {
            a
            for attr in db_helpers.get_attribute_names(cls.__name__)
            for a in db_helpers.get_attribute_fields(attr)
        }

    @classmethod
    def relation_names(cls):
        return set(db_helpers.get_relation_names(cls.__name__))

    @classmethod
    def state_names(cls):
        return set(db_helpers.get_state_names(cls.__name__))

    @classmethod
    def verify_args(cls, temporality=False, search=False):
        req_args = set(cls._get_args())

        if temporality:
            req_args -= TEMPORALITY_PARAMS

        if search:
            req_args -= GENERAL_SEARCH_PARAMS
            req_args -= TEMPORALITY_PARAMS
            req_args -= cls.attribute_names()
            req_args -= cls.state_names()

            # special handling of argument with an object type
            req_args -= {
                a
                for a in req_args
                if split_param(a)[0] in cls.relation_names()
            }

        if req_args:
            arg_string = ', '.join(sorted(req_args))
            raise BadRequestException('Unsupported argument(s): {}'
                                      .format(arg_string))
