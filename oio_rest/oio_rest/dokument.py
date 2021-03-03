# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

import flask

from . import db
from .authentication import requires_auth
from .contentstore import content_store
from .db import db_helpers

from .oio_base import OIORestObject, OIOStandardHierarchy


class Dokument(OIORestObject):
    """
    Implement a Dokument  - manage access to database layer from the API.
    """

    @classmethod
    @requires_auth
    def download_content(cls, content_path):
        """
        Download a content file, given a content path.
        """
        content_url = "store:%s" % content_path

        # Get the document UUID, and the content's mimetype associated with
        # the content URL
        uuid, mimetype = db.get_document_from_content_url(content_url)

        # Read in the object. This will throw a NotFoundException if the
        # document does not exist, OR another exception if the user does not
        # have access to it.
        db.list_objects(cls.__name__, [uuid], None, None, None, None)

        filename = content_store.get_filename_for_url(content_url)

        # Send the file efficiently, if possible
        return flask.send_file(filename, mimetype=mimetype)

    @classmethod
    def create_api(cls, hierarchy):
        """Set up API with correct database access functions."""
        rest_router = super(Dokument, cls).create_api(hierarchy)
        hierarchy = hierarchy.lower()
        class_url = "/{0}/{1}".format(hierarchy, cls.__name__.lower())
        # TODO: Fix url to FASTAPI
        uuid_regex = (
            "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}"
            "-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}"
        )
        date_path_regex = "\\d{4}/\\d{2}/\\d{2}/\\d{2}/\\d{2}/" + uuid_regex + ".bin"
        download_content_url = '{0}/<regex("{1}"):content_path>'.format(
            class_url, date_path_regex
        )

        rest_router.get(download_content_url, name="_".join([cls.__name__, "download_content"]))(cls.download_content)

        return rest_router

    @classmethod
    def gather_registration(cls, input):
        attributes = input.get("attributter", {})
        states = input.get("tilstande", {})
        relations = input.get("relationer", {})
        variants = input.get("varianter", [])
        return {
            "states": states,
            "attributes": attributes,
            "relations": relations,
            "variants": variants,
        }

    @classmethod
    def relation_names(cls):
        extra = set(db_helpers.get_document_part_relation_names())

        return super().relation_names() | extra

    @classmethod
    def attribute_names(cls):
        return super().attribute_names() | {"varianttekst", "deltekst"}


class DokumentHierarki(OIOStandardHierarchy):
    """Implement the Dokument Standard."""

    _name = "Dokument"
    _classes = [Dokument]
