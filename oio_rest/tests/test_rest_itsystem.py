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
