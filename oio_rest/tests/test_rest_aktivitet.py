import unittest
import uuid

from oio_rest.utils.build_registration import is_uuid
from tests import util


class TestAktivitet(util.TestCase):
    def test_aktivitet(self):
        result = self.client.post(
            "aktivitet/aktivitet",
            data={
                "json": open("tests/fixtures/aktivitet_opret.json", "rt").read(),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.get_json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

        with self.subTest("Update aktivitet"):
            result_patch = self.client.patch(
                "aktivitet/aktivitet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/aktivitet_opdater.json", "rt").read(),
                },
            )
            self.assertEqual(result_patch.status_code, 200)
            self.assertEqual(result_patch.get_json()["uuid"], uuid_)
