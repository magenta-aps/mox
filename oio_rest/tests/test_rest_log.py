# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


from oio_rest.utils.build_registration import is_uuid
from tests import util
from tests.util import DBTestCase


class TestLogHaendelse(DBTestCase):
    def test_log_haendelse(self):
        result = self.client.post(
            "log/loghaendelse",
            data={
                "json": util.get_fixture("loghaendelse_opret.json",
                                         as_text=False),
            },
        )
        self.assertEqual(result.status_code, 201, result.json)
        uuid_ = result.get_json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

        with self.subTest("Import loghaendelse"):
            result_import = self.client.patch(
                "log/loghaendelse/%s" % uuid_,
                data={
                    "json": util.get_fixture("loghaendelse_opdater.json",
                                             as_text=False),
                },
            )
            self.assertEqual(result_import.status_code, 200)
            self.assertEqual(result_import.get_json()["uuid"], uuid_)

        with self.subTest("Delete loghaendelse"):
            result_delete = self.client.delete(
                "log/loghaendelse/%s" % uuid_,
                data={
                    "json": util.get_fixture("loghaendelse_slet.json",
                                             as_text=False),
                },
            )
            self.assertEqual(result_delete.status_code, 202)
            self.assertEqual(result_delete.get_json()["uuid"], uuid_)
