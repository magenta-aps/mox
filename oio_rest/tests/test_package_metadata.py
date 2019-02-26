#
# Copyright (c) 2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

import os
import re
import unittest

from . import util


class VersionTest(unittest.TestCase):
    def test_versions(self):
        with open(os.path.join(util.TOP_DIR, 'VERSION')) as fp:
            main_version = fp.read().strip()

        with open(os.path.join(util.TOP_DIR, 'NEWS.rst')) as fp:
            all_versions = re.findall(r'^Version ([^,]*),', fp.read(),
                                      re.MULTILINE)

        readme_version = all_versions[0]

        self.assertIn(main_version, all_versions)
        self.assertEqual(main_version, readme_version)
