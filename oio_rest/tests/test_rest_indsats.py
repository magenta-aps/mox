# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


import uuid

from oio_rest.utils import is_uuid
from tests import util
from tests.util import DBTestCase


class TestIndsats(DBTestCase):
    def test_indsats_create(self):
        result = self.client.post(
            "indsats/indsats",
            data={
                "json": util.get_fixture("indsats_opret.json", as_text=False),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.get_json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

    def test_indsats_put(self):
        uuid_ = str(uuid.uuid4())
        result = self.client.put(
            "indsats/indsats/%s" % uuid_,
            data={
                "json": util.get_fixture("indsats_opret.json", as_text=False),
            },
        )
        self.assertEqual(result.status_code, 200)
        self.assertEqual(result.get_json()["uuid"], uuid_)
