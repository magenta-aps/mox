# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


class ContentStore:
    def get_filename_for_url(self, url):
        """Return the full path on the file-system for the URL.

        The URL should be of the form `store:my/sub/path/to/file.bin"""
        raise NotImplementedError

    def save_file_object(self, file_obj):
        """Save the file to the content store. Return the content URL.

        The object is expected to be a werkzeug.datastructures.FileStorage
        object."""
        raise NotImplementedError

    def remove(self, url):
        """Remove the file specified by the given content URL."""
        raise NotImplementedError


content_store = ContentStore()
