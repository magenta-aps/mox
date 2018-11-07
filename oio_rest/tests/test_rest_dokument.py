import unittest
import uuid

from oio_rest.utils import test_support
from oio_rest.utils.build_registration import is_uuid


class TestDokument(test_support.TestRestInterface):
    @unittest.skip("I don't know what should happen here.")
    def test_create_dokument_empty_dict(self):
        result = self.client.post(
            "/dokument/dokument",
            data={"json": "{}"},
        ).get_json()
        assert result["uuid"] is not None

    def test_create_dokument_missing_files(self):
        result = self.client.post(
            "/dokument/dokument",
            data={
                "json": open("tests/fixtures/dokument_opret.json", "rb").read(),
            }
        ).get_json()
        assert "uuid" not in result and result["message"]

    @unittest.expectedFailure
    def test_dokument(self):
        with self.subTest("Upload dokument"):
            result = self.client.post(
                "/dokument/dokument",
                content_type="multipart/form-data",
                data={
                    "json": open("tests/fixtures/dokument_opret.json", "rt").read(),
                    "del_indhold1": ("tests/fixtures/test.txt", "del_indhold1"),
                    "del_indhold2": ("tests/fixtures/test.docx", "del_indhold2"),
                    "del_indhold3": ("tests/fixtures/test.xls", "del_indhold3"),
                }
            ).get_json()
            assert is_uuid(result["uuid"])
            upload_uuid = result["uuid"]  # the subtests rely on this variable

        import_uuid = str(uuid.uuid4())
        import_uuid_b = str(uuid.uuid4()).encode("utf-8")
        with self.subTest("Import dokument"):
            result = self.client.put(
                "/dokument/dokument/%s" % import_uuid,
                content_type="multipart/form-data",
                data={
                    "json": open("tests/fixtures/dokument_opret.json", "rt").read(),
                    "del_indhold1": ("tests/fixtures/test.txt", "del_indhold1"),
                    "del_indhold2": ("tests/fixtures/test.docx", "del_indhold2"),
                    "del_indhold3": ("tests/fixtures/test.xls", "del_indhold3"),
                }
            ).get_json()
            assert is_uuid(result["uuid"]) and result["uuid"] == import_uuid

        files = []
        with self.subTest("List files / get content urls"):
            for r in self.client.get(
                "dokument/dokument",
                query_string={"uuid": upload_uuid},
            ).get_json()["results"][0][0]["registreringer"][0]["varianter"][0]["dele"]:
                path = r["egenskaber"][0]["indhold"]
                if path.startswith("store:"):
                    files.append(path[6:])
                else:
                    pass
                    # the test data makes one of these a link to google
                    # what does that mean?
                    # print(path, "is not a store: path", file=sys.stderr)
            assert len(files) == 2

        for filename in files:
            with self.subTest("Download dokument", filename=filename):
                assert b"This is a test" == self.client.get("dokument/dokument/%s" % filename).get_data()

        with self.subTest("Search on DokumentDel relations"):
            # currently doesnt accept parameter "variant", redmine issue #24569
            assert "message" not in self.client.get(
                "dokument/dokument",
                query_string={
                    "variant": "doc_varianttekst2",
                    "deltekst": "doc_deltekst2B",
                    "underredigeringaf": "urn:cpr8883394",
                    "uuid": upload_uuid,
                }
            ).get_json()

        with self.subTest("Update dokument"):
            result = self.client.patch(
                "/dokument/dokument",
                content_type="multipart/form-data",
                data={
                    "json": open("tests/fixtures/dokument_opdater.json", "rt").read(),
                },
                query_string={"uuid": upload_uuid},
            )
            assert result.status_code == 200

        with self.subTest("Download updated dokument"):
            result = self.client.get(
                "dokument/dokument",
                query_string={"uuid": upload_uuid},
            ).get_json()
            assert result["results"][0][0]["registreringer"][0]["note"] == "Opdateret dokument"

        with self.subTest("Update dokument with file upload"):
            result = self.client.patch(
                 "/dokument/dokument",
                content_type="multipart/form-data",
                data={
                    "json": open("tests/fixtures/dokument_opdater2.json", "rt").read(),
                    "del_indhold1_opdateret": ("tests/fixtures/test2.txt",
                    "del_indhold1_opdateret"),
                },
                query_string={"uuid": upload_uuid},
            )
            assert result.status_code == 200

        with self.subTest("Download updated dokument 2"):
            result = self.client.get(
                "dokument/dokument", query_string={"uuid": upload_uuid})
            assert result.status_code == 200
            for r in result.get_json()["results"][0][0]["registreringer"][0]["varianter"][0]["dele"]:
                path = r["egenskaber"][0]["indhold"]
                if path.startswith("store:"):
                    if b"This is an updated test" in self.client.get("dokument/dokument/%s" % path[6:]).get_data():
                        break
            else:
                assert 0, "Uploaded file was not updated"

        with self.subTest("Delete DokumentDel relation"):
            assert self.client.get(
                "dokument/dokument/",
                query_string={
                    "variant": "doc_varianttekst2",
                    "deltekst": "doc_deltekst2B",
                    "underredigeringaf": "urn:cpr8883394",
                    "uuid": upload_uuid,
                },
            ).status_code == 200

        with self.subTest("Passivate dokument"):
            assert self.client.patch(
                "dokument/dokument/%s" % upload_uuid,
                data=open("tests/fixtures/facet_passiv.json", "rt").read(),
            ).status_code == 200

        with self.subTest("Delete dokument"):
            assert self.client.delete(
                "dokument/dokument/%s" % upload_uuid,
                data=open("tests/fixtures/dokument_slet.json", "rt").read(),
            ).status_code == 200

        with self.subTest("Search on imported dokument"):
            r = self.client.get(
                "dokument/dokument",
                query_string={
                    "produktion": "true",
                    "virkningfra": "2015-05-20",
                    "uuid": import_uuid,
                },
            )
            assert r.status_code == 200
            assert import_uuid_b not in r.get_data()

        with self.subTest("Search for del 1"):
            # currently doesnt accept parameter mimetype, redmine issue #24631
            r = self.client.get(
                "dokument/dokument",
                query_string={
                    "varianttekst": "PDF",
                    "deltekst": "doc_deltekst1A",
                    "mimetype": "text/plain",
                    "uuid": import_uuid,
                },
            )
            assert r.status_code == 200
            assert import_uuid_b in r.get_data()

        with self.subTest("Search for del 2"):
            r = self.client.get(
                "dokument/dokument",
                query_string={
                    "deltekst": "doc_deltekst1A",  # is this correct? it was
                    # like this in the bash tests
                    "mimetype": "text/plain",
                    "uuid": import_uuid,
                },
            )
            assert r.status_code == 200
            assert import_uuid_b in r.get_data()

        with self.subTest("Search on del relation URN"):
            r = self.client.get(
                "dokument/dokument",
                query_string={
                    "underredigeringaf": "urn:cpr8883394",
                    "uuid": import_uuid,
                },
            )
            assert r.status_code == 200
            assert import_uuid_b in r.get_data()

        with self.subTest("Search on relation with objekttype"):
            # currently doesnt't accept objekttype parameter, redmine issue
            # #24634. Should also handle non-existant objekttypes, as shown in
            # next test
            r = self.client.get(
                "dokument/dokument",
                query_string={
                    "ejer": "Organisation=ef2713ee-1a38-4c23-8fcb-3c4331262194",
                    "uuid": import_uuid,
                },
            )
            assert r.status_code == 200
            assert import_uuid_b in r.get_data()

        with self.subTest("Search on relation with invalid objekttype"):
            r = self.client.get(
                "dokument/dokument",
                query_string={
                    "ejer": "Blah=ef2713ee-1a38-4c23-8fcb-3c4331262194",
                    "uuid": import_uuid,
                },
            )
            assert r.status_code != 200
            assert import_uuid_b not in r.get_data()

        with self.subTest("Search on del relation with objekttype"):
            r = self.client.get(
                "dokument/dokument",
                query_string={
                    "underredigeringaf": "Bruger=urn:cpr8883394",
                    "uuid": import_uuid,
                },
            )
            assert r.status_code == 200
            assert import_uuid_b in r.get_data()
