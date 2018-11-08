import unittest
import uuid

from oio_rest.utils.build_registration import is_uuid
from tests import util


class TestIndsats(util.TestCase):
    def test_indsats_create(self):
        result = self.client.post(
            "indsats/indsats",
            data={
                "json": open("tests/fixtures/indsats_opret.json", "rt").read(),
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
                "json": open("tests/fixtures/indsats_opret.json", "rt").read(),
            },
        )
        self.assertEqual(result.status_code, 200)
        self.assertEqual(result.get_json()["uuid"], uuid_)
