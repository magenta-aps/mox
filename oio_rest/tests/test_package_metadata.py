# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

import os
import re
import unittest

from oio_rest import __version__

from . import util


class VersionTest(unittest.TestCase):
    def test_versions(self):
        main_version = __version__

        with open(os.path.join(util.TOP_DIR, 'NEWS.rst')) as fp:
            all_versions = re.findall(r'^Version ([^,]*),', fp.read(),
                                      re.MULTILINE)

        readme_version = all_versions[0]

        self.assertIn(main_version, all_versions)
        self.assertEqual(main_version, readme_version)
