#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
import json

from . import util


class Tests(util.TestCase):

    def test_virkningstid(self):
        uuid = "931ee7bf-10d6-4cc3-8938-83aa6389aaba"

        self.load_fixture('/organisation/bruger', 'test_bruger.json', uuid)

        expected = util.get_fixture(
            'output/test_bruger_virkningstid.json')

        actual = self.get_json_result('/organisation/bruger', uuid=uuid,
                                      virkningstid='2004-01-01')

        self.assertRegistrationsEqual(expected, actual)
