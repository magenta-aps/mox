# encoding: utf-8

import os
from flask import jsonify
from contentstore import content_store

from oio_rest import OIORestObject, OIOStandardHierarchy, db
from authentication import requires_auth

class Dokument(OIORestObject):
    """
    Implement a Dokument  - manage access to database layer from the API.
    """
    @classmethod
    @requires_auth
    def create_object(cls):
        input = cls.get_json()
        if not input:
            return jsonify({'uuid': None}), 400

        # Temporarily for now, look for a "content" field on the main
        # json object, so we can test file upload.
        # This should really look into the DokumentDel subobject for this field
        content_url = input.get("content", "")
        f = cls._get_file_storage_for_content_url(content_url)

        # TODO: Wrap in try/except block, turn off autocommit, and roll back
        # db transaction if file saving fails

        # Save the file and get the URL for the saved file
        stored_content_url = "content:%s" % content_store.save_file_object(f)
        print stored_content_url

        # TODO: Refactor to extract common functionality in superclass and
        # call superclass method instead of duplicating code.

        note = input.get("note", "")
        attributes = input.get("attributter", {})
        states = input.get("tilstande", {})
        relations = input.get("relationer", {})
        uuid = db.create_or_import_object(cls.__name__, note, attributes,
                                          states, relations)
        return jsonify({'uuid': uuid}), 201


class DokumentsHierarki(OIOStandardHierarchy):
    """Implement the Dokument Standard."""

    _name = "Dokument"
    _classes = [Dokument]
