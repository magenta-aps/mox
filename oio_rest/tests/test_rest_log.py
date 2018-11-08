import unittest
import uuid

from oio_rest.utils.build_registration import is_uuid
from tests import util


class TestLogHaendelse(util.TestCase):
    def test_log_haendelse(self):
        result = self.client.post(
            "log/loghaendelse",
            data={
                "json": open("tests/fixtures/loghaendelse_opret.json", "rt").read(),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.get_json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

        with self.subTest("Import loghaendelse"):
            result_import = self.client.patch(
                "log/loghaendelse/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/loghaendelse_opdater.json", "rt").read(),
                },
            )
            self.assertEqual(result_import.status_code, 200)
            self.assertEqual(result_import.get_json()["uuid"], uuid_)

        with self.subTest("Delete loghaendelse"):
            result_delete = self.client.delete(
                "log/loghaendelse/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/loghaendelse_slet.json", "rt").read(),
                },
            )
            self.assertEqual(result_delete.status_code, 202)
            self.assertEqual(result_delete.get_json()["uuid"], uuid_)
