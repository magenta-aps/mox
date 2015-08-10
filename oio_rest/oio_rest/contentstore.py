# encoding: utf-8

import os
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
        return "%s.bin" % uuid.uuid4()

    def _get_file_sub_path(self):
        """Return the path relative to the file upload dir for a new file."""
        dir_list = time.strftime("%Y %m %d %H %M %S", time.gmtime()).split()
        return os.path.join(*dir_list)

    def save_file_object(self, file_obj):
        file_name = self._get_new_file_name()
        sub_path = self._get_file_sub_path()
        full_path = os.path.join(FILE_UPLOAD_FOLDER, sub_path)
        _mkdir_p(full_path)
        file_obj.save(os.path.join(full_path, file_name))
        return os.path.join(sub_path, file_name)


content_store = ContentStore()
