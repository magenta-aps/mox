import unittest
import uuid

from oio_rest.utils.build_registration import is_uuid
from tests import util


class Test21660PutUpdate(util.TestCase):
    def test_21660(self):
        result = self.client.post(
            "klassifikation/facet",
            data={
                "json": open("tests/fixtures/facet_opret.json", "rt").read(),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.get_json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

        result_put = self.client.put(
            "klassifikation/facet/%s" % uuid_,
            data={
                "json": open("tests/fixtures/facet_reduce_effective_time_21660.json", "rt").read(),
            },
        )
        self.assertEqual(result_put.status_code, 200)
        self.assertEqual(result_put.get_json()["uuid"], uuid_)


class TestKlasse(util.TestCase):
    def test_klasse(self):
        result = self.client.post(
            "klassifikation/klasse",
            data={
                "json": open("tests/fixtures/klasse_opret.json", "rt").read(),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.get_json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

        result_patch = self.client.patch(
            "klassifikation/klasse/%s" % uuid_,
            data={
                "json": open("tests/fixtures/klasse_opdater.json", "rt").read(),
            },
        )
        self.assertEqual(result_patch.status_code, 200)
        self.assertEqual(result_patch.get_json()["uuid"], uuid_)


class TestImportDeletedPassivated(util.TestCase):
    def test_import_delete_passivated(self):
        result = self.client.post(
            "klassifikation/facet",
            data={
                "json": open("tests/fixtures/facet_opret.json", "rt").read(),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.get_json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

        with self.subTest("Passivate object"):
            result_patch = self.client.patch(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_passiv.json", "rt").read(),
                },
            )
            self.assertEqual(result_patch.status_code, 200)
            self.assertEqual(result_patch.get_json()["uuid"], uuid_)

        with self.subTest("Import object"):
            result_put = self.client.put(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_opret.json", "rt").read(),
                },
            )
            self.assertEqual(result_put.status_code, 200)
            self.assertEqual(result_put.get_json()["uuid"], uuid_)

        with self.subTest("Delete object"):
            result_delete = self.client.delete(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_slet.json", "rt").read(),
                },
            )
            self.assertEqual(result_delete.status_code, 202)
            self.assertEqual(result_delete.get_json()["uuid"], uuid_)

        with self.subTest("Import object"):
            result_import = self.client.put(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_opret.json", "rt").read(),
                },
            )
            self.assertEqual(result_import.status_code, 200)
            self.assertEqual(result_import.get_json()["uuid"], uuid_)


class TestFacet(util.TestCase):
    def test_facet(self):
        result = self.client.post(
            "klassifikation/facet",
            data={
                "json": open("tests/fixtures/facet_opret.json", "rt").read(),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.get_json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

        import_uuid = str(uuid.uuid4())
        with self.subTest("Import new facet"):
            result_import = self.client.put(
                "klassifikation/facet/%s" % import_uuid,
                data={
                    "json": open("tests/fixtures/facet_opret.json", "rt").read(),
                },
            )
            self.assertEqual(result_import.status_code, 200)
            self.assertEqual(result_import.get_json()["uuid"], import_uuid)

        with self.subTest("Update facet"):
            result_patch = self.client.patch(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_opdater.json", "rt").read(),
                },
            )
            self.assertEqual(result_patch.status_code, 200)
            self.assertEqual(result_patch.get_json()["uuid"], uuid_)

        with self.subTest("Replace the facet content with old ones"):
            result_put = self.client.put(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_opret.json", "rt").read(),
                },
            )
            self.assertEqual(result_put.status_code, 200)
            self.assertEqual(result_put.get_json()["uuid"], uuid_)

        with self.subTest("Passivate facet"):
            result_patch = self.client.patch(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_passiv.json", "rt").read(),
                },
            )
            self.assertEqual(result_patch.status_code, 200)
            self.assertEqual(result_patch.get_json()["uuid"], uuid_)

        with self.subTest("Delete facet"):
            result_delete = self.client.delete(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_slet.json", "rt").read(),
                },
            )
            self.assertEqual(result_delete.status_code, 202)
            self.assertEqual(result_delete.get_json()["uuid"], uuid_)