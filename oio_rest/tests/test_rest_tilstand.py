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
