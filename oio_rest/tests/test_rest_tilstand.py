# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

import uuid

from oio_rest.utils import is_uuid
from tests import util
from tests.util import DBTestCase


class TestTilstand(DBTestCase):
    def test_tilstand_create(self):
        result = self.client.post(
            "tilstand/tilstand",
            data={
                "json": util.get_fixture("tilstand_opret.json", as_text=False),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

    def test_tilstand_put(self):
        uuid_ = str(uuid.uuid4())
        result = self.client.put(
            "tilstand/tilstand/%s" % uuid_,
            data={
                "json": util.get_fixture("tilstand_opret.json", as_text=False),
            },
        )
        self.assertEqual(result.status_code, 200)
        self.assertEqual(result.json()["uuid"], uuid_)
