# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import StringIO
import os
import ConfigParser


def read_properties_files(*file_paths):
    data = {}
    for file_path in file_paths:
        try:
            with open(file_path) as f:
                config = StringIO.StringIO()
                config.write('[dummy_section]\n')
                config.write(f.read().replace('%', '%%'))
                config.seek(0, os.SEEK_SET)

                cp = ConfigParser.SafeConfigParser()
                cp.readfp(config)

                data.update(dict(cp.items('dummy_section')))
        except IOError:
            pass
    return data


class MissingConfigKeyError(Exception):
    def __init__(self, key):
        super(MissingConfigKeyError, self).__init__(
            'Missing configuration key: %s' % key
        )
