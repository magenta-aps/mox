# encoding: utf-8

import os
from urlparse import urlparse
import uuid
import errno
import time

from settings import FILE_UPLOAD_FOLDER


def _mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise


class ContentStore:
    def _get_new_file_name(self):
        """Return a newly generated filename based on a random UUID."""
        return "%s.bin" % uuid.uuid4()

    def _get_file_sub_path(self):
        """Return the path relative to the file upload dir for a new file."""
        dir_list = time.strftime("%Y %m %d %H %M", time.gmtime()).split()
        return os.path.join(*dir_list)

    def _get_path_for_url(self, url):
        """Return the full path on the file-system for the URL.

        The URL should be of the form `store:my/sub/path/to/file.bin"""
        o = urlparse(url)
        if o.scheme != 'store':
            raise Exception("Content store supports only URL scheme 'store'")
        return os.path.join(FILE_UPLOAD_FOLDER, o.path)

    def save_file_object(self, file_obj):
        """Save the file to the content store. Return the content URL.

        The object is expected to be a werkzeug.datastructures.FileStorage
        object."""
        while True:
            file_name = self._get_new_file_name()
            sub_path = self._get_file_sub_path()
            full_path = os.path.join(FILE_UPLOAD_FOLDER, sub_path)
            full_file_path = os.path.join(full_path, file_name)
            try:
                os.stat(full_file_path)
                # Keep looping, until we generate a file name that doesn't
                # already exist.
            except OSError, e:
                # The file didn't exist already, so it is safe to create it
                _mkdir_p(full_path)
                file_obj.save(full_file_path)
                return "store:%s" % os.path.join(sub_path, file_name)

    def remove(self, url):
        """Remove the file specified by the given content URL."""
        path = self._get_path_for_url(url)
        os.remove(path)

        # Try to cleanup any intermediary directories.
        try:
            head, tail = os.path.split(path)
            os.removedirs(head)
        except OSError:
            # It's okay, the directory was not empty, leave it alone
            pass


content_store = ContentStore()
