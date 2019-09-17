#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

from tests import util
from tests.util import DBTestCase


class Tests(DBTestCase):

    def test_virkningstid(self):
        uuid = "931ee7bf-10d6-4cc3-8938-83aa6389aaba"

        self.load_fixture('/organisation/bruger', 'test_bruger.json', uuid)

        expected = util.get_fixture(
            'output/test_bruger_virkningstid.json')

        self.assertQueryResponse('/organisation/bruger', expected,
                                 uuid=uuid, virkningstid='2004-01-01')

    def test_empty_update(self):
        # Ensure that nothing is deleted when an empty update is made
        # Arrange
        uuid = "931ee7bf-10d6-4cc3-8938-83aa6389aaba"
        path = '/organisation/bruger'

        self.load_fixture(path, 'test_bruger.json', uuid)

        expected = self.get(path, uuid=uuid)
        expected['livscykluskode'] = 'Rettet'

        update = {
            'egenskaber': {},
            'tilstande': {},
            'relationer': {}
        }

        # Act
        self.patch("{}/{}".format(path, uuid), json=update)

        # Assert
        actual = self.get(path, uuid=uuid)

        self.assertRegistrationsEqual(expected, actual)
