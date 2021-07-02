# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

"""Superclasses for OIO objects and object hierarchies."""
import json
import datetime
from abc import ABCMeta, abstractmethod
from typing import Dict, List, Optional, Tuple, Union
from uuid import UUID

import dateutil
import jsonschema
from fastapi import APIRouter, Request, HTTPException
from werkzeug.datastructures import ImmutableOrderedMultiDict
from werkzeug.exceptions import BadRequest

from . import db, validate, config
from .custom_exceptions import BadRequestException, GoneException, NotFoundException
from .db import db_helpers, db_structure
from .db.quick_query.search import quick_search
from .utils import build_registration, split_param, to_lower_param

"""List of parameters allowed for all searches."""
GENERAL_SEARCH_PARAMS = frozenset(
    {
        "brugerref",
        "foersteresultat",
        "livscykluskode",
        "maximalantalresultater",
        "notetekst",
        "uuid",
        "vilkaarligattr",
        "vilkaarligrel",
        "list",
    }
)

"""List of parameters allowed the apply to temporal operations, i.e.
search and list.

"""
TEMPORALITY_PARAMS = frozenset(
    {
        "registreretfra",
        "registrerettil",
        "registreringstid",
        "virkningfra",
        "virkningtil",
        "virkningstid",
    }
)

"""Parameter used for consolidating virkninger in output. For list, search
and get"""
CONSOLIDATE_PARAM = frozenset(
    {
        "konsolider",
    }
)

"""Some operations take no arguments; this makes it explicit."""
NO_PARAMS = frozenset()

"""Aliases that apply to all operations."""
PARAM_ALIASES = {
    "bvn": "brugervendtnoegle",
}


class Searcher(metaclass=ABCMeta):
    @abstractmethod
    def search_objects(
        self,
        class_name: str,
        uuid: Optional[str],
        registration: Dict,
        virkning_fra: Union[datetime.datetime, str],
        virkning_til: Union[datetime.datetime, str],
        registreret_fra: Optional[Union[datetime.datetime, str]] = None,
        registreret_til: Optional[Union[datetime.datetime, str]] = None,
        life_cycle_code=None,
        user_ref=None,
        note=None,
        any_attr_value_arr=None,
        any_rel_uuid_arr=None,
        first_result=None,
        max_results=None,
    ) -> Tuple[List[str]]:
        pass


class DefaultSearcher(Searcher):
    @staticmethod
    def search_objects(
        class_name: str,
        uuid: Optional[str],
        registration: Dict,
        virkning_fra: Union[datetime.datetime, str],
        virkning_til: Union[datetime.datetime, str],
        registreret_fra: Optional[Union[datetime.datetime, str]] = None,
        registreret_til: Optional[Union[datetime.datetime, str]] = None,
        life_cycle_code=None,
        user_ref=None,
        note=None,
        any_attr_value_arr=None,
        any_rel_uuid_arr=None,
        first_result=None,
        max_results=None,
    ) -> Tuple[List[str]]:
        return db.search_objects(
            class_name=class_name,
            uuid=uuid,
            registration=registration,
            virkning_fra=virkning_fra,
            virkning_til=virkning_til,
            registreret_fra=registreret_fra,
            registreret_til=registreret_til,
            life_cycle_code=life_cycle_code,
            user_ref=user_ref,
            note=note,
            any_attr_value_arr=any_attr_value_arr,
            any_rel_uuid_arr=any_rel_uuid_arr,
            first_result=first_result,
            max_results=max_results,
        )


class QuickSearcher(Searcher):
    @staticmethod
    def search_objects(
        class_name: str,
        uuid: Optional[str],
        registration: Dict,
        virkning_fra: Union[datetime.datetime, str],
        virkning_til: Union[datetime.datetime, str],
        registreret_fra: Optional[Union[datetime.datetime, str]] = None,
        registreret_til: Optional[Union[datetime.datetime, str]] = None,
        life_cycle_code=None,
        user_ref=None,
        note=None,
        any_attr_value_arr=None,
        any_rel_uuid_arr=None,
        first_result=None,
        max_results=None,
    ) -> Tuple[List[str]]:
        try:
            return quick_search(
                class_name=class_name,
                uuid=uuid,
                registration=registration,
                virkning_fra=virkning_fra,
                virkning_til=virkning_til,
                registreret_fra=registreret_fra,
                registreret_til=registreret_til,
                life_cycle_code=life_cycle_code,
                user_ref=user_ref,
                note=note,
                any_attr_value_arr=any_attr_value_arr,
                any_rel_uuid_arr=any_rel_uuid_arr,
                first_result=first_result,
                max_results=max_results,
            )
        except NotImplementedError:
            return db.search_objects(
                class_name=class_name,
                uuid=uuid,
                registration=registration,
                virkning_fra=virkning_fra,
                virkning_til=virkning_til,
                registreret_fra=registreret_fra,
                registreret_til=registreret_til,
                life_cycle_code=life_cycle_code,
                user_ref=user_ref,
                note=note,
                any_attr_value_arr=any_attr_value_arr,
                any_rel_uuid_arr=any_rel_uuid_arr,
                first_result=first_result,
                max_results=max_results,
            )


class ConfiguredDBInterface:
    def __init__(self):
        if config.get_settings().quick_search:
            self.searcher: Searcher = QuickSearcher()
        else:
            self.searcher: Searcher = DefaultSearcher()


configured_db_interface = ConfiguredDBInterface()


def typed_get(d, field, default):
    v = d.get(field, default)
    t = type(default)

    if v is None:
        return default

    if not isinstance(v, t):
        raise BadRequestException(
            "expected %s for %r, found %s: %s"
            % (t.__name__, field, type(v).__name__, json.dumps(v))
        )

    return v


def get_virkning_dates(args):
    virkning_fra = args.get("virkningfra")
    virkning_til = args.get("virkningtil")
    virkningstid = args.get("virkningstid")

    if virkningstid:
        if virkning_fra or virkning_til:
            raise BadRequestException(
                "'virkningfra'/'virkningtil' conflict " "with 'virkningstid'"
            )
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
            virkning_til = virkning_fra + datetime.timedelta(microseconds=1)
    return virkning_fra, virkning_til


def get_registreret_dates(args):
    registreret_fra = args.get("registreretfra")
    registreret_til = args.get("registrerettil")
    registreringstid = args.get("registreringstid")

    if registreringstid:
        if registreret_fra or registreret_til:
            raise BadRequestException(
                "'registreretfra'/'registrerettil' " "conflict with 'registreringstid'"
            )
        else:
            # Timespan has to be non-zero length of time, so we add one
            # microsecond
            dt = dateutil.parser.isoparse(registreringstid)
            registreret_fra = dt
            registreret_til = dt + datetime.timedelta(microseconds=1)
    return registreret_fra, registreret_til


def _check_not_deleted(objects):
    """Raise 410 Gone if any object is deleted."""
    if objects is None:
        return
    for obj in objects:
        if (
            isinstance(obj, list)
            and obj[0]["registreringer"][0]["livscykluskode"]
            == db.Livscyklus.SLETTET.value
        ):
            raise GoneException(
                "The object with UUID %s has been deleted." % obj[0]["id"]
            )


class ArgumentDict(ImmutableOrderedMultiDict):
    """
    A Werkzeug multi dict that maintains the order, and maps alias
    arguments.
    """

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
        super(ArgumentDict, self).__init__(list(map(self._process_item, mapping)))


class Registration:
    def __init__(self, oio_class, states, attributes, relations):
        self.oio_class = oio_class
        self.states = states
        self.attributes = attributes
        self.relations = relations


class OIOStandardHierarchy:
    """Implement API for entire hierarchy."""

    _name = ""
    _classes = []

    @classmethod
    def setup_api(cls):
        """Set up API for the classes included in the hierarchy.

        Note that version number etc. may have to be added to the URL."""

        assert cls._name and cls._classes, "hierarchy not configured?"

        oio_router = APIRouter()

        for c in cls._classes:
            router = c.create_api(cls._name)
            oio_router.include_router(router)

        hierarchy = cls._name.lower()
        classes_url = "/{0}/{1}".format(hierarchy, "classes")

        @oio_router.get(classes_url, name="_".join([hierarchy, "classes"]))
        def get_classes():
            """Return the classes including their fields under this service.

            .. :quickref: :http:get:`/(service)/classes`

            """
            structure = db_structure.REAL_DB_STRUCTURE
            clsnms = [c.__name__.lower() for c in cls._classes]
            hierarchy_dict = {c: structure[c] for c in clsnms}
            return hierarchy_dict

        return oio_router


class OIORestObject:
    """
    Implement an OIO object - manage access to database layer for this object.

    This class is intended to be subclassed, but not to be initialized.
    """

    # The name of the current service. This is set by the create_api() method.
    service_name = None

    @classmethod
    async def get_json(cls, request: Request):
        """
        Return the JSON input from the request.
        The JSON input typically comes from the body of the request with
        Content-Type: application/json. However, for POST/PUT operations
        involving multipart/form-data, the JSON input is expected to be
        contained in a form field called 'json'. This method handles this in a
        consistent way.
        """
        try:
            return await request.json()
        except json.decoder.JSONDecodeError:
            formset = await request.form()
            data = formset.get("json", None)
            if data is not None:
                try:
                    return json.loads(data)
                except ValueError:
                    raise BadRequest()
            else:
                return None

    @classmethod
    async def create_object(cls, request: Request):
        """A :ref:`CreateOperation` that creates a new object from the JSON
        payload. It returns a newly generated UUID for the created object.

        .. :quickref: :ref:`CreateOperation`

        """

        cls.verify_args(request)

        input = await cls.get_json(request)
        if not input:
            raise HTTPException(status_code=400, detail={"uuid": None})

        # Validate JSON input
        try:
            validate.validate(input, cls.__name__.lower())
        except jsonschema.exceptions.ValidationError as e:
            raise HTTPException(status_code=400, detail={"message": e.message})

        note = typed_get(input, "note", "")
        registration = cls.gather_registration(input)
        uuid = db.create_or_import_object(cls.__name__, note, registration)
        # Pass log info on request object.
        # request.api_operation = "Opret"
        # request.uuid = uuid
        return {"uuid": uuid}

    @classmethod
    def _get_args(cls, request: Request, as_lists=False, preprocess=False):
        """
        Convert arguments to lowercase, optionally getting them as lists.
        """
        query_params = request.query_params
        items = ArgumentDict(query_params.multi_items())

        return {
            to_lower_param(k): items.getlist(k) if as_lists else items.get(k)
            for k in items
        }

    @classmethod
    async def get_objects(cls, request: Request):
        """A :ref:`ListOperation` or :ref:`SearchOperation` depending on parameters.

        With any the of ``uuid``, ``virking*`` and ``registeret*`` parameters,
        it is a :ref:`ListOperation` and will return one or more whole JSON
        objects.

        Given any other parameters, the operation is a :ref:`SearchOperation`
        and will only return a list of UUIDs to the objects.

        .. :quickref: :ref:`ListOperation` or :ref:`SearchOperation`

        """
        cls.verify_args(
            request, search=True, temporality=True, consolidate=True, preprocess=True
        )

        # Convert arguments to lowercase, getting them as lists
        list_args = cls._get_args(request, True, preprocess=True)
        args = cls._get_args(request, preprocess=True)
        registreret_fra, registreret_til = get_registreret_dates(args)
        virkning_fra, virkning_til = get_virkning_dates(args)

        uuid_param = list_args.get("uuid", None)

        consolidate_param = list_args.get("konsolider") is not None
        if consolidate_param:
            list_fn = db.list_and_consolidate_objects
        else:
            list_fn = db.list_objects

        valid_list_args = TEMPORALITY_PARAMS | CONSOLIDATE_PARAM | {"uuid"}

        # Assume the search operation if other params were specified or the
        # 'list' parameter is specified
        if not (valid_list_args.issuperset(args) and args.get("list") is None):

            # Only one uuid is supported through the search operation
            if uuid_param is not None and len(uuid_param) > 1:
                raise BadRequestException(
                    "Multiple uuid parameters passed "
                    "to search operation. Only one "
                    "uuid parameter is supported."
                )
            uuid_param = args.get("uuid", None)
            first_result = args.get("foersteresultat", None)
            if first_result is not None:
                first_result = int(first_result)
            max_results = args.get("maximalantalresultater", None)
            if max_results is not None:
                max_results = int(max_results)

            any_attr_value_arr = list_args.get("vilkaarligattr", None)
            any_rel_uuid_arr = list_args.get("vilkaarligrel", None)
            life_cycle_code = args.get("livscykluskode", None)
            user_ref = args.get("brugerref", None)
            note = args.get("notetekst", None)

            # Fill out a registration object based on the query arguments
            registration = build_registration(cls.__name__, list_args)
            # request.api_operation = "Søg"
            results = configured_db_interface.searcher.search_objects(
                cls.__name__,
                uuid_param,
                registration,
                virkning_fra,
                virkning_til,
                registreret_fra,
                registreret_til,
                life_cycle_code,
                user_ref,
                note,
                any_attr_value_arr,
                any_rel_uuid_arr,
                first_result,
                max_results,
            )

            if args.get("list") is not None:
                # request.api_operation = "List"
                results = list_fn(
                    cls.__name__,
                    results[0],
                    virkning_fra,
                    virkning_til,
                    registreret_fra,
                    registreret_til,
                )
                _check_not_deleted(results)

        else:
            uuid_param = list_args.get("uuid", None)
            # request.api_operation = "List"
            results = list_fn(
                cls.__name__,
                uuid_param,
                virkning_fra,
                virkning_til,
                registreret_fra,
                registreret_til,
            )
            _check_not_deleted(results)

        if results is None:
            results = []
        # if uuid_param:
        #    request.uuid = uuid_param
        # else:
        #    request.uuid = ""
        return {"results": results}

    @classmethod
    async def get_object(cls, uuid: UUID, request: Request):
        """A :ref:`ReadOperation`. Return a single whole object as a JSON object.

        .. :quickref: :ref:`ReadOperation`

        """
        uuid = str(uuid)
        cls.verify_args(request, temporality=True, consolidate=True)

        args = cls._get_args(request)
        registreret_fra, registreret_til = get_registreret_dates(args)

        virkning_fra, virkning_til = get_virkning_dates(args)

        consolidate_param = cls._get_args(request).get("konsolider") is not None
        if consolidate_param:
            list_fn = db.list_and_consolidate_objects
        else:
            list_fn = db.list_objects

        # request.api_operation = "Læs"
        # request.uuid = uuid
        object_list = list_fn(
            cls.__name__,
            [uuid],
            virkning_fra,
            virkning_til,
            registreret_fra,
            registreret_til,
        )
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
        if (
            object[0]["registreringer"][0]["livscykluskode"]
            == db.Livscyklus.SLETTET.value
        ):
            raise GoneException("This object has been deleted.")
        return {uuid: object}

    @classmethod
    def gather_registration(cls, input):
        """Return a registration dict from the input dict."""
        attributes = typed_get(input, "attributter", {})
        states = typed_get(input, "tilstande", {})

        relations = typed_get(input, "relationer", {})
        filtered_relations = {key: val for key, val in relations.items() if val}

        return {
            "states": states,
            "attributes": attributes,
            "relations": filtered_relations,
        }

    @classmethod
    async def put_object(cls, uuid: UUID, request: Request):
        """A :ref:`ImportOperation` that creates or overwrites an object from
        the JSON payload.  It returns the UUID for the object.

        If there is no object with the UUID or the object with that UUID was
        :ref:`deleted <DeleteOperation>` or :ref:`passivated
        <PassivateOperation>`, it creates a new object at the specified UUID.
        It sets ``livscykluskode: "Importeret"``.

        If an object with the UUID exists, it completely overwrites the object
        including all ``virkning`` periods. It sets
        ``livscykluskode: "Rettet"``.

        .. :quickref: :ref:`ImportOperation`

        """
        uuid = str(uuid)
        cls.verify_args(request)

        input = await cls.get_json(request)
        if not input:
            raise HTTPException(status_code=400, detail={"uuid": None})

        # Validate JSON input
        try:
            validate.validate(input, cls.__name__.lower())
        except jsonschema.exceptions.ValidationError as e:
            raise HTTPException(status_code=400, detail={"message": e.message})

        # Get most common parameters if available.
        note = typed_get(input, "note", "")
        registration = cls.gather_registration(input)
        exists = db.object_exists(cls.__name__, uuid)
        deleted_or_passive = False
        if exists:
            livscyklus = db.get_life_cycle_code(cls.__name__, uuid)
            if (
                livscyklus == db.Livscyklus.PASSIVERET.value
                or livscyklus == db.Livscyklus.SLETTET.value
            ):
                deleted_or_passive = True

        # request.uuid = uuid

        if not exists:
            # Do import.
            # request.api_operation = "Import"
            db.create_or_import_object(cls.__name__, note, registration, uuid)
        elif deleted_or_passive:
            # Import.
            # request.api_operation = "Import"
            db.update_object(
                cls.__name__,
                note,
                registration,
                uuid=uuid,
                life_cycle_code=db.Livscyklus.IMPORTERET.value,
            )
        else:
            # Edit.
            # request.api_operation = "Ret"
            db.create_or_import_object(cls.__name__, note, registration, uuid)
        return {"uuid": uuid}

    @classmethod
    async def patch_object(cls, uuid: UUID, request: Request):
        """An :ref:`UpdateOperation` or :ref:`PassivateOperation`. Apply the
        JSON payload as a change to the object. Return the UUID of the object.

        If ``livscyklus: "Passiv"`` is set it is a :ref:`PassivateOperation`.

        .. :quickref: :ref:`UpdateOperation` or :ref:`PassivateOperation`

        """
        # TODO: Why no cls.verify_args here
        uuid = str(uuid)

        # If the object doesn't exist, we can't patch it.
        if not db.object_exists(cls.__name__, uuid):
            raise NotFoundException(
                "No {} with ID {} found in service {}".format(
                    cls.__name__, uuid, cls.service_name
                )
            )

        input = await cls.get_json(request)
        if not input:
            raise HTTPException(status_code=400, detail={"uuid": None})

        # Get most common parameters if available.
        note = typed_get(input, "note", "")
        registration = cls.gather_registration(input)

        # Validate JSON input
        try:
            validate.validate(input, cls.__name__.lower(), do_create=False)
        except jsonschema.exceptions.ValidationError as e:
            raise HTTPException(status_code=400, detail={"message": e.message})

        if typed_get(input, "livscyklus", "").lower() == "passiv":
            # Passivate
            # request.api_operation = "Passiver"
            registration = cls.gather_registration({})
            db.passivate_object(cls.__name__, note, registration, uuid)
        else:
            # Edit/change
            # request.api_operation = "Ret"
            db.update_object(cls.__name__, note, registration, uuid)
        return {"uuid": uuid}

    @classmethod
    async def delete_object(cls, uuid: UUID, request: Request):
        """A :ref:`DeleteOperation`. Delete the object and return the UUID.

        .. :quickref: :ref:`DeleteOperation`

        """
        uuid = str(uuid)

        cls.verify_args(request)

        input = await cls.get_json(request) or {}
        note = typed_get(input, "note", "")
        class_name = cls.__name__
        # Gather a blank registration
        registration = cls.gather_registration({})
        # request.api_operation = "Slet"
        # request.uuid = uuid
        db.delete_object(class_name, registration, note, uuid)

        return {"uuid": uuid}

    @classmethod
    def get_fields(cls, request: Request):
        """Return a list of all fields a given object has.

        .. :quickref: :http:get:`/(service)/(object)/fields`

        """
        cls.verify_args(request)

        """Set up API with correct database access functions."""
        structure = db_structure.REAL_DB_STRUCTURE
        class_key = cls.__name__.lower()
        # TODO: Perform some transformations to improve readability.
        class_dict = structure[class_key]
        return class_dict

    @classmethod
    def get_schema(cls, request: Request):
        """Returns the JSON schema of an object.

        .. :quickref: :http:get:`/(service)/(object)/schema`

        """
        cls.verify_args(request)

        return validate.get_schema(cls.__name__.lower())

    @classmethod
    def create_api(cls, hierarchy):
        """Set up API with correct database access functions."""
        cls.service_name = hierarchy
        hierarchy = hierarchy.lower()
        class_name = cls.__name__.lower()
        class_url = "/{0}/{1}".format(hierarchy, class_name)
        cls_fields_url = "{0}/{1}".format(class_url, "fields")
        object_url = class_url + "/{uuid}"

        rest_router = APIRouter()

        rest_router.get(class_url, name="_".join([cls.__name__, "get_objects"]))(
            cls.get_objects
        )
        rest_router.post(
            class_url, name="_".join([cls.__name__, "create_object"]), status_code=201
        )(cls.create_object)

        # Structure URLs
        rest_router.get(cls_fields_url, name="_".join([cls.__name__, "fields"]))(
            cls.get_fields
        )
        # JSON schemas
        rest_router.get(
            "{0}/{1}".format(class_url, "schema"),
            name="_".join([cls.__name__, "schema"]),
        )(cls.get_schema)

        rest_router.get(object_url, name="_".join([cls.__name__, "get_object"]))(
            cls.get_object
        )
        rest_router.put(object_url, name="_".join([cls.__name__, "put_object"]))(
            cls.put_object
        )
        rest_router.patch(object_url, name="_".join([cls.__name__, "patch_object"]))(
            cls.patch_object
        )
        rest_router.delete(
            object_url, name="_".join([cls.__name__, "delete_object"]), status_code=202
        )(cls.delete_object)

        return rest_router

    # Templates which may be overridden on subclass.
    # Templates may only be overridden on subclass if they are explicitly
    # listed here.
    RELATIONS_TEMPLATE = "relations_array.sql"

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
    def verify_args(
        cls,
        request: Request,
        temporality=False,
        search=False,
        consolidate=False,
        *args,
        **kwargs
    ):
        req_args = set(cls._get_args(request, *args, **kwargs))

        if temporality:
            req_args -= TEMPORALITY_PARAMS

        if consolidate:
            req_args -= CONSOLIDATE_PARAM

        if search:
            req_args -= GENERAL_SEARCH_PARAMS
            req_args -= TEMPORALITY_PARAMS
            req_args -= cls.attribute_names()
            req_args -= cls.state_names()

            # special handling of argument with an object type
            req_args -= {
                a for a in req_args if split_param(a)[0] in cls.relation_names()
            }

        if req_args:
            arg_string = ", ".join(sorted(req_args))
            raise BadRequestException("Unsupported argument(s): {}".format(arg_string))
