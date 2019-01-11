# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import unittest
import uuid

from oio_rest.utils.build_registration import is_uuid
from tests import util


class TestTilstand(util.TestCase):
    def test_tilstand_create(self):
        result = self.client.post(
            "tilstand/tilstand",
            data={
                "json": open("tests/fixtures/tilstand_opret.json", "rt").read(),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.get_json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

    def test_tilstand_put(self):
        uuid_ = str(uuid.uuid4())
        result = self.client.put(
            "tilstand/tilstand/%s" % uuid_,
            data={
                "json": open("tests/fixtures/tilstand_opret.json", "rt").read(),
            },
        )
        self.assertEqual(result.status_code, 200)
        self.assertEqual(result.get_json()["uuid"], uuid_)
