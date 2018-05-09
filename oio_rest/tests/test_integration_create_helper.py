#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

import json
import uuid

from tests import util


class TestCreateObject(util.TestCase):
    def setUp(self):
        super(TestCreateObject, self).setUp()
        self.standard_virkning1 = {
            "from": "2000-01-01 12:00:00+01",
            "from_included": True,
            "to": "2020-01-01 12:00:00+01",
            "to_included": False
        }
        self.standard_virkning2 = {
            "from": "2020-01-01 12:00:00+01",
            "from_included": True,
            "to": "2030-01-01 12:00:00+01",
            "to_included": False
        }
        self.reference = {
            'uuid': '00000000-0000-0000-0000-000000000000',
            'virkning': self.standard_virkning1
        }

    def assertUUID(self, s):
        try:
            uuid.UUID(s)
        except (TypeError, ValueError):
            self.fail('{!r} is not a uuid!'.format(s))

    def assert201(self, response):
        """
        Verify that the response from LoRa is 201 and contains the correct
        JSON.
        :param response: Response from LoRa when creating a new object
        """
        self.assertEquals(201, response.status_code)
        self.assertEquals(1, len(response.json))
        self.assertUUID(response.json['uuid'])

    # def check_response_400(self, url, obj):
    #     self.assertRequestFails(url, 400, json=obj)
