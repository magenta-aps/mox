# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import uuid

from oio_rest.utils.build_registration import is_uuid
from tests import util
from tests.util import DBTestCase


class Test21660PutUpdate(DBTestCase):
    def test_21660(self):
        result = self.client.post(
            "klassifikation/facet",
            data={
                "json": util.get_fixture("facet_opret.json", as_text=False),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.get_json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

        result_put = self.client.put(
            "klassifikation/facet/%s" % uuid_,
            data={
                "json": util.get_fixture(
                    "facet_reduce_effective_time_21660.json",
                    as_text=False,
                ),
            },
        )
        self.assertEqual(result_put.status_code, 200)
        self.assertEqual(result_put.get_json()["uuid"], uuid_)


class TestKlasse(DBTestCase):
    def test_klasse(self):
        result = self.client.post(
            "klassifikation/klasse",
            data={
                "json": util.get_fixture("klasse_opret.json", as_text=False),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.get_json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

        result_patch = self.client.patch(
            "klassifikation/klasse/%s" % uuid_,
            data={
                "json": util.get_fixture("klasse_opdater.json", as_text=False),
            },
        )
        self.assertEqual(result_patch.status_code, 200)
        self.assertEqual(result_patch.get_json()["uuid"], uuid_)


class TestImportDeletedPassivated(DBTestCase):
    def test_import_delete_passivated(self):
        result = self.client.post(
            "klassifikation/facet",
            data={
                "json": util.get_fixture("facet_opret.json", as_text=False),
            },
        )
        self.assertEqual(result.status_code, 201)
        uuid_ = result.get_json()["uuid"]
        self.assertTrue(is_uuid(uuid_))

        with self.subTest("Passivate object"):
            result_patch = self.client.patch(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": util.get_fixture("facet_passiv.json",
                                             as_text=False),
                },
            )
            self.assertEqual(result_patch.status_code, 200)
            self.assertEqual(result_patch.get_json()["uuid"], uuid_)

        with self.subTest("Import object"):
            result_put = self.client.put(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": util.get_fixture("facet_opret.json",
                                             as_text=False),
                },
            )
            self.assertEqual(result_put.status_code, 200)
            self.assertEqual(result_put.get_json()["uuid"], uuid_)

        with self.subTest("Delete object"):
            result_delete = self.client.delete(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": util.get_fixture("facet_slet.json",
                                             as_text=False),
                },
            )
            self.assertEqual(result_delete.status_code, 202)
            self.assertEqual(result_delete.get_json()["uuid"], uuid_)

        with self.subTest("Import object"):
            result_import = self.client.put(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": util.get_fixture("facet_opret.json",
                                             as_text=False),
                },
            )
            self.assertEqual(result_import.status_code, 200)
            self.assertEqual(result_import.get_json()["uuid"], uuid_)


class TestFacet(DBTestCase):
    def test_facet(self):
        result = self.client.post(
            "klassifikation/facet",
            data={
                "json": util.get_fixture("facet_opret.json",
                                         as_text=False),
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
                    "json": util.get_fixture("facet_opret.json",
                                             as_text=False),
                },
            )
            self.assertEqual(result_import.status_code, 200)
            self.assertEqual(result_import.get_json()["uuid"], import_uuid)

        with self.subTest("Update facet"):
            result_patch = self.client.patch(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": util.get_fixture("facet_opdater.json",
                                             as_text=False),
                },
            )
            self.assertEqual(result_patch.status_code, 200)
            self.assertEqual(result_patch.get_json()["uuid"], uuid_)

        with self.subTest("Replace the facet content with old ones"):
            result_put = self.client.put(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": util.get_fixture("facet_opret.json",
                                             as_text=False),
                },
            )
            self.assertEqual(result_put.status_code, 200)
            self.assertEqual(result_put.get_json()["uuid"], uuid_)

        with self.subTest("Passivate facet"):
            result_patch = self.client.patch(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": util.get_fixture("facet_passiv.json",
                                             as_text=False),
                },
            )
            self.assertEqual(result_patch.status_code, 200)
            self.assertEqual(result_patch.get_json()["uuid"], uuid_)

        with self.subTest("Delete facet"):
            result_delete = self.client.delete(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": util.get_fixture("facet_slet.json",
                                             as_text=False),
                },
            )
            self.assertEqual(result_delete.status_code, 202)
            self.assertEqual(result_delete.get_json()["uuid"], uuid_)
