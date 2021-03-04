# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


import unittest
import uuid

from oio_rest.utils import is_uuid
from tests import util
from tests.util import DBTestCase


class TestDokument(DBTestCase):
    def test_create_dokument_empty_dict(self):
        """Not sure why this happens?"""
        self.assertRequestResponse(
            "/dokument/dokument", {"uuid": None}, json={}, status_code=400
        )

    def test_create_dokument_missing_files(self):
        result = self.client.post(
            "/dokument/dokument", json=util.get_fixture("dokument_opret.json")
        ).json()
        self.assertNotIn("uuid", result)
        self.assertTrue(result["message"])

    @unittest.expectedFailure
    def test_dokument(self):
        with self.subTest("Upload dokument"):
            result = self.client.post(
                "/dokument/dokument",
                content_type="multipart/form-data",
                data={
                    "json": util.get_fixture("dokument_opret.json", as_text=False),
                    "del_indhold1": (
                        "tests/fixtures/test.txt",
                        "del_indhold1",
                    ),
                    "del_indhold2": (
                        "tests/fixtures/test.docx",
                        "del_indhold2",
                    ),
                    "del_indhold3": (
                        "tests/fixtures/test.xls",
                        "del_indhold3",
                    ),
                },
            ).json()
            self.assertTrue(is_uuid(result["uuid"]))
            upload_uuid = result["uuid"]  # the subtests rely on this variable

        import_uuid = str(uuid.uuid4())
        import_uuid_b = str(uuid.uuid4()).encode("utf-8")
        with self.subTest("Import dokument"):
            result = self.client.put(
                "/dokument/dokument/%s" % import_uuid,
                content_type="multipart/form-data",
                data={
                    "json": util.get_fixture("dokument_opret.json", as_text=False),
                    "del_indhold1": (
                        "tests/fixtures/test.txt",
                        "del_indhold1",
                    ),
                    "del_indhold2": (
                        "tests/fixtures/test.docx",
                        "del_indhold2",
                    ),
                    "del_indhold3": (
                        "tests/fixtures/test.xls",
                        "del_indhold3",
                    ),
                },
            ).json()
            self.assertTrue(is_uuid(result["uuid"]))
            self.assertEqual(result["uuid"], import_uuid)

        files = []
        with self.subTest("List files / get content urls"):
            for r in self.client.get(
                "dokument/dokument", params={"uuid": upload_uuid}
            ).json()["results"][0][0]["registreringer"][0]["varianter"][0]["dele"]:
                path = r["egenskaber"][0]["indhold"]
                if path.startswith("store:"):
                    files.append(path[6:])
                else:
                    pass
                    # the test data makes one of these a link to google
                    # what does that mean?
                    # print(path, "is not a store: path", file=sys.stderr)
            self.assertEqual(len(files), 2)

        for filename in files:
            with self.subTest("Download dokument", filename=filename):
                self.assertEqual(
                    b"This is a test",
                    self.client.get("dokument/dokument/%s" % filename).get_data(),
                )

        with self.subTest("Search on DokumentDel relations"):
            # currently doesnt accept parameter "variant", redmine issue #24569
            self.assertNotIn(
                "message",
                self.client.get(
                    "dokument/dokument",
                    params={
                        "variant": "doc_varianttekst2",
                        "deltekst": "doc_deltekst2B",
                        "underredigeringaf": "urn:cpr8883394",
                        "uuid": upload_uuid,
                    },
                ).json,
            )

        with self.subTest("Update dokument"):
            result = self.client.patch(
                "/dokument/dokument",
                content_type="multipart/form-data",
                data={"json": util.get_fixture("dokument_opdater.json", as_text=False)},
                params={"uuid": upload_uuid},
            )
            self.assertEqual(result.status_code, 200)

        with self.subTest("Download updated dokument"):
            result = self.client.get(
                "dokument/dokument", params={"uuid": upload_uuid}
            ).json()
            self.assertEqual(
                result["results"][0][0]["registreringer"][0]["note"],
                "Opdateret dokument",
            )

        with self.subTest("Update dokument with file upload"):
            result = self.client.patch(
                "/dokument/dokument",
                content_type="multipart/form-data",
                data={
                    "json": util.get_fixture("dokument_opdater2.json", as_text=False),
                    "del_indhold1_opdateret": (
                        "tests/fixtures/test2.txt",
                        "del_indhold1_opdateret",
                    ),
                },
                params={"uuid": upload_uuid},
            )
            self.assertEqual(result.status_code, 200)

        with self.subTest("Download updated dokument 2"):
            result = self.client.get(
                "dokument/dokument", params={"uuid": upload_uuid}
            )
            self.assertEqual(result.status_code, 200)
            for r in result.json()["results"][0][0]["registreringer"][0][
                "varianter"
            ][0]["dele"]:
                path = r["egenskaber"][0]["indhold"]
                if path.startswith("store:"):
                    if (
                        b"This is an updated test"
                        in self.client.get("dokument/dokument/%s" % path[6:]).get_data()
                    ):
                        break
            else:
                raise NotImplementedError("Uploaded file was not updated")

        with self.subTest("Delete DokumentDel relation"):
            self.assertEqual(
                self.client.get(
                    "dokument/dokument/",
                    params={
                        "variant": "doc_varianttekst2",
                        "deltekst": "doc_deltekst2B",
                        "underredigeringaf": "urn:cpr8883394",
                        "uuid": upload_uuid,
                    },
                ).status_code,
                200,
            )

        with self.subTest("Passivate dokument"):
            self.assertEqual(
                self.client.patch(
                    "dokument/dokument/%s" % upload_uuid,
                    data=util.get_fixture("facet_passiv.json", as_text=False),
                ).status_code,
                200,
            )

        with self.subTest("Delete dokument"):
            self.assertEqual(
                self.client.delete(
                    "dokument/dokument/%s" % upload_uuid,
                    data=util.get_fixture("dokument_slet.json", as_text=False),
                ).status_code,
                200,
            )

        with self.subTest("Search on imported dokument"):
            r = self.client.get(
                "dokument/dokument",
                params={
                    "produktion": "true",
                    "virkningfra": "2015-05-20",
                    "uuid": import_uuid,
                },
            )
            self.assertEqual(r.status_code, 200)
            self.assertNotIn(import_uuid_b, r.get_data())

        with self.subTest("Search for del 1"):
            # currently doesnt accept parameter mimetype, redmine issue #24631
            r = self.client.get(
                "dokument/dokument",
                params={
                    "varianttekst": "PDF",
                    "deltekst": "doc_deltekst1A",
                    "mimetype": "text/plain",
                    "uuid": import_uuid,
                },
            )
            self.assertEqual(r.status_code, 200)
            self.assertIn(import_uuid_b, r.get_data())

        with self.subTest("Search for del 2"):
            r = self.client.get(
                "dokument/dokument",
                params={
                    "deltekst": "doc_deltekst1A",  # is this correct? it was
                    # like this in the bash tests
                    "mimetype": "text/plain",
                    "uuid": import_uuid,
                },
            )
            self.assertEqual(r.status_code, 200)
            self.assertIn(import_uuid_b, r.get_data())

        with self.subTest("Search on del relation URN"):
            r = self.client.get(
                "dokument/dokument",
                params={
                    "underredigeringaf": "urn:cpr8883394",
                    "uuid": import_uuid,
                },
            )
            self.assertEqual(r.status_code, 200)
            self.assertIn(import_uuid_b, r.get_data())

        with self.subTest("Search on relation with objekttype"):
            # currently doesnt't accept objekttype parameter, redmine issue
            # #24634. Should also handle non-existant objekttypes, as shown in
            # next test
            r = self.client.get(
                "dokument/dokument",
                params={
                    "ejer": "Organisation=ef2713ee-1a38-4c23-8fcb-3c4331262194",
                    "uuid": import_uuid,
                },
            )
            self.assertEqual(r.status_code, 200)
            self.assertIn(import_uuid_b, r.get_data())

        with self.subTest("Search on relation with invalid objekttype"):
            r = self.client.get(
                "dokument/dokument",
                params={
                    "ejer": "Blah=ef2713ee-1a38-4c23-8fcb-3c4331262194",
                    "uuid": import_uuid,
                },
            )
            self.assertNotEqual(r.status_code != 200)
            self.assertNotIn(import_uuid_b, r.get_data())

        with self.subTest("Search on del relation with objekttype"):
            r = self.client.get(
                "dokument/dokument",
                params={
                    "underredigeringaf": "Bruger=urn:cpr8883394",
                    "uuid": import_uuid,
                },
            )
            self.assertEqual(r.status_code, 200)
            self.assertIn(import_uuid_b, r.get_data())
