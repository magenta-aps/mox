# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import unittest

from oio_rest.utils.build_registration import is_uuid
from tests import util


class TestItSystem(util.TestCase):
    def test_it_system(self):
        result = self.client.post(
            "organisation/itsystem",
            data={
                "json": open("tests/fixtures/itsystem_opret.json", "rt").read(),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.get_json()["uuid"]
        self.assertTrue(is_uuid(uuid_))
