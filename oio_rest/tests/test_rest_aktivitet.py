# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


from oio_rest.utils import is_uuid
from tests import util
from tests.util import DBTestCase


class TestAktivitet(DBTestCase):
    def test_aktivitet(self):
        result = self.client.post(
            "aktivitet/aktivitet",
            data={
                "json": util.get_fixture("aktivitet_opret.json", as_text=False),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

        with self.subTest("Update aktivitet"):
            result_patch = self.client.patch(
                "aktivitet/aktivitet/%s" % uuid_,
                data={
                    "json": util.get_fixture("aktivitet_opdater.json", as_text=False),
                },
            )
            self.assertEqual(result_patch.status_code, 200)
            self.assertEqual(result_patch.json()["uuid"], uuid_)
