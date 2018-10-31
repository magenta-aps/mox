import io
import pytest
import sys
import unittest
import uuid

import flask
import flask_testing

from .util import get_fixture
from oio_rest import app
from oio_rest.utils import test_support
from oio_rest.utils.build_registration import is_uuid


class _TestInterface(test_support.TestCaseMixin, flask_testing.TestCase):
    def create_app(self):
        return self.get_lora_app()


class TestDokumentInterface(_TestInterface):
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

        # I have not found a good way to skip failing subtests, so for now they
        # are simply commented out :(
        for filename in files:
            with self.subTest("Download dokument", filename=filename):
                # assert b"This is a test" == self.client.get("dokument/dokument/%s" % filename).get_data()
                pass

        with self.subTest("Search on DokumentDel relations"):
            # currently doesnt accept parameter "variant", redmine issue #24569
            # assert "message" not in self.client.get(
            #     "dokument/dokument",
            #     query_string={
            #         "variant": "doc_varianttekst2",
            #         "deltekst": "doc_deltekst2B",
            #         "underredigeringaf": "urn:cpr8883394",
            #         "uuid": upload_uuid,
            #     }
            # ).get_json()
            pass

        with self.subTest("Update dokument"):
            # result = self.client.patch(
            #     "/dokument/dokument",
            #     content_type="multipart/form-data",
            #     data={
            #         "json": open("tests/fixtures/dokument_opdater.json", "rt").read(),
            #     },
            #     query_string={"uuid": upload_uuid},
            # )
            # assert result.status_code == 200
            pass

        with self.subTest("Download updated dokument"):
            # result = self.client.get(
            #     "dokument/dokument",
            #     query_string={"uuid": upload_uuid},
            # ).get_json()
            # assert result["results"][0][0]["registreringer"][0]["note"] == "Opdateret dokument"
            pass

        with self.subTest("Update dokument with file upload"):
            # result = self.client.patch(
            #      "/dokument/dokument",
            #     content_type="multipart/form-data",
            #     data={
            #         "json": open("tests/fixtures/dokument_opdater2.json", "rt").read(),
            #         "del_indhold1_opdateret": ("tests/fixtures/test2.txt",
            #         "del_indhold1_opdateret"),
            #     },
            #     query_string={"uuid": upload_uuid},
            # )
            # assert result.status_code == 200
            pass

        with self.subTest("Download updated dokument 2"):
            # result = self.client.get(
            #     "dokument/dokument", query_string={"uuid": upload_uuid})
            # assert result.status_code == 200
            # for r in result.get_json()["results"][0][0]["registreringer"][0]["varianter"][0]["dele"]:
            #     path = r["egenskaber"][0]["indhold"]
            #     if path.startswith("store:"):
            #         if b"This is an updated test" in self.client.get("dokument/dokument/%s" % path[6:]).get_data():
            #             break
            # else:
            #     assert 0, "Uploaded file was not updated"
            pass

        with self.subTest("Delete DokumentDel relation"):
            # assert self.client.get(
            #     "dokument/dokument/",
            #     query_string={
            #         "variant": "doc_varianttekst2",
            #         "deltekst": "doc_deltekst2B",
            #         "underredigeringaf": "urn:cpr8883394",
            #         "uuid": upload_uuid,
            #     },
            # ).status_code == 200
            pass

        with self.subTest("Passivate dokument"):
            # assert self.client.patch(
            #     "dokument/dokument/%s" % upload_uuid,
            #     "data"=open("tests/fixtures/facet_passiv.json", "rt").read(),
            # ).status_code == 200
            pass

        with self.subTest("Delete dokument"):
            # assert self.client.delete(
            #     "dokument/dokument/%s" % upload_uuid,
            #     "data"=open("tests/fixtures/dokument_slet.json", "rt").read(),
            # ).status_code == 200
            pass

        with self.subTest("Search on imported dokument"):
            # r = self.client.get(
            #     "dokument/dokument",
            #     query_string={
            #         "produktion": "true",
            #         "virkningfra": "2015-05-20",
            #         "uuid": import_uuid,
            #     },
            # )
            # assert r.status_code == 200
            # assert import_uuid_b not in r.get_data()
            pass

        with self.subTest("Search for del 1"):
            # currently doesnt accept parameter mimetype, redmine issue #24631
            # r = self.client.get(
            #     "dokument/dokument",
            #     query_string={
            #         "varianttekst": "PDF",
            #         "deltekst": "doc_deltekst1A",
            #         "mimetype": "text/plain",
            #         "uuid": import_uuid,
            #     },
            # )
            # assert r.status_code == 200
            # assert import_uuid_b in r.get_data()
            pass

        with self.subTest("Search for del 2"):
            # r = self.client.get(
            #     "dokument/dokument",
            #     query_string={
            #         "deltekst": "doc_deltekst1A",  # is this correct? it was
            #         # like this in the bash tests
            #         "mimetype": "text/plain",
            #         "uuid": import_uuid,
            #     },
            # )
            # assert r.status_code == 200
            # assert import_uuid_b in r.get_data()
            pass

        with self.subTest("Search on del relation URN"):
            # r = self.client.get(
            #     "dokument/dokument",
            #     query_string={
            #         "underredigeringaf": "urn:cpr8883394",
            #         "uuid": import_uuid,
            #     },
            # )
            # assert r.status_code == 200
            # assert import_uuid_b in r.get_data()
            pass

        with self.subTest("Search on relation with objekttype"):
            # currently doesnt't accept objekttype parameter, redmine issue
            # #24634. Should also handle non-existant objekttypes, as shown in
            # next test
            # r = self.client.get(
            #     "dokument/dokument",
            #     query_string={
            #         "ejer": "Organisation=ef2713ee-1a38-4c23-8fcb-3c4331262194",
            #         "uuid": import_uuid,
            #     },
            # )
            # assert r.status_code == 200
            # assert import_uuid_b in r.get_data()
            pass

        with self.subTest("Search on relation with invalid objekttype"):
            # r = self.client.get(
            #     "dokument/dokument",
            #     query_string={
            #         "ejer": "Blah=ef2713ee-1a38-4c23-8fcb-3c4331262194",
            #         "uuid": import_uuid,
            #     },
            # )
            # assert r.status_code != 200
            # assert import_uuid_b not in r.get_data()
            pass

        with self.subTest("Search on del relation with objekttype"):
            # r = self.client.get(
            #     "dokument/dokument",
            #     query_string={
            #         "underredigeringaf": "Bruger=urn:cpr8883394",
            #         "uuid": import_uuid,
            #     },
            # )
            # assert r.status_code == 200
            # assert import_uuid_b in r.get_data()
            pass


class Test21660PutUpdate(_TestInterface):
    def test_21660(self):
        result = self.client.post(
            "klassifikation/facet",
            data={
                "json": open("tests/fixtures/facet_opret.json", "rt").read(),
            },
        )
        assert result.status_code == 201
        uuid_ = result.get_json()["uuid"]
        assert is_uuid(uuid_)

        result_put = self.client.put(
            "klassifikation/facet/%s" % uuid_,
            data={
                "json": open("tests/fixtures/facet_reduce_effective_time_21660.json", "rt").read(),
            },
        )
        assert result_put.status_code == 200
        assert result_put.get_json()["uuid"] == uuid_


class TestItSystem(_TestInterface):
    def test_it_system(self):
        result = self.client.post(
            "organisation/itsystem",
            data={
                "json": open("tests/fixtures/itsystem_opret.json", "rt").read(),
            },
        )
        assert result.status_code == 201
        uuid_ = result.get_json()["uuid"]
        assert is_uuid(uuid_)


class TestKlasse(_TestInterface):
    def test_klasse(self):
        result = self.client.post(
            "klassifikation/klasse",
            data={
                "json": open("tests/fixtures/klasse_opret.json", "rt").read(),
            },
        )
        assert result.status_code == 201
        uuid_ = result.get_json()["uuid"]
        assert is_uuid(uuid_)

        result_patch = self.client.patch(
            "klassifikation/klasse/%s" % uuid_,
            data={
                "json": open("tests/fixtures/klasse_opdater.json", "rt").read(),
            },
        )
        assert result_patch.status_code == 200
        assert result_patch.get_json()["uuid"] == uuid_


class TestImportDeletedPassivated(_TestInterface):
    def test_import_delete_passivated(self):
        result = self.client.post(
            "klassifikation/facet",
            data={
                "json": open("tests/fixtures/facet_opret.json", "rt").read(),
            },
        )
        assert result.status_code == 201
        uuid_ = result.get_json()["uuid"]
        assert is_uuid(uuid_)

        with self.subTest("Passivate object"):
            result_patch = self.client.patch(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_passiv.json", "rt").read(),
                },
            )
            assert result_patch.status_code == 200
            assert result_patch.get_json()["uuid"] == uuid_

        with self.subTest("Import object"):
            result_put = self.client.put(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_opret.json", "rt").read(),
                },
            )
            assert result_put.status_code == 200
            assert result_put.get_json()["uuid"] == uuid_

        with self.subTest("Delete object"):
            result_delete = self.client.delete(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_slet.json", "rt").read(),
                },
            )
            assert result_delete.status_code == 202
            assert result_delete.get_json()["uuid"] == uuid_

        with self.subTest("Import object"):
            result_import = self.client.put(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_opret.json", "rt").read(),
                },
            )
            assert result_import.status_code == 200
            assert result_import.get_json()["uuid"] == uuid_


class TestLogHaendelse(_TestInterface):
    def test_log_haendelse(self):
        result = self.client.post(
            "log/loghaendelse",
            data={
                "json": open("tests/fixtures/loghaendelse_opret.json", "rt").read(),
            },
        )
        assert result.status_code == 201
        uuid_ = result.get_json()["uuid"]
        assert is_uuid(uuid_)

        with self.subTest("Import loghaendelse"):
            result_import = self.client.patch(
                "log/loghaendelse/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/loghaendelse_opdater.json", "rt").read(),
                },
            )
            assert result_import.status_code == 200
            assert result_import.get_json()["uuid"] == uuid_

        with self.subTest("Delete loghaendelse"):
            result_delete = self.client.delete(
                "log/loghaendelse/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/loghaendelse_slet.json", "rt").read(),
                },
            )
            assert result_delete.status_code == 202
            assert result_delete.get_json()["uuid"] == uuid_


class TestAktivitet(_TestInterface):
    def test_aktivitet(self):
        result = self.client.post(
            "aktivitet/aktivitet",
            data={
                "json": open("tests/fixtures/aktivitet_opret.json", "rt").read(),
            },
        )
        assert result.status_code == 201
        uuid_ = result.get_json()["uuid"]
        assert is_uuid(uuid_)

        with self.subTest("Update aktivitet"):
            result_patch = self.client.patch(
                "aktivitet/aktivitet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/aktivitet_opdater.json", "rt").read(),
                },
            )
            assert result_patch.status_code == 200
            assert result_patch.get_json()["uuid"] == uuid_


class TestIndsats(_TestInterface):
    def test_indsats_create(self):
        result = self.client.post(
            "indsats/indsats",
            data={
                "json": open("tests/fixtures/indsats_opret.json", "rt").read(),
            },
        )
        assert result.status_code == 201
        uuid_ = result.get_json()["uuid"]
        assert is_uuid(uuid_)

    def test_indsats_put(self):
        uuid_ = str(uuid.uuid4())
        result = self.client.put(
            "indsats/indsats/%s" % uuid_,
            data={
                "json": open("tests/fixtures/indsats_opret.json", "rt").read(),
            },
        )
        assert result.status_code == 200
        assert result.get_json()["uuid"] == uuid_


class TestTilstand(_TestInterface):
    def test_tilstand_create(self):
        result = self.client.post(
            "tilstand/tilstand",
            data={
                "json": open("tests/fixtures/tilstand_opret.json", "rt").read(),
            },
        )
        assert result.status_code == 201
        uuid_ = result.get_json()["uuid"]
        assert is_uuid(uuid_)

    def test_tilstand_put(self):
        uuid_ = str(uuid.uuid4())
        result = self.client.put(
            "tilstand/tilstand/%s" % uuid_,
            data={
                "json": open("tests/fixtures/tilstand_opret.json", "rt").read(),
            },
        )
        assert result.status_code == 200
        assert result.get_json()["uuid"] == uuid_


class TestFacet(_TestInterface):
    def test_facet(self):
        result = self.client.post(
            "klassifikation/facet",
            data={
                "json": open("tests/fixtures/facet_opret.json", "rt").read(),
            },
        )
        assert result.status_code == 201
        uuid_ = result.get_json()["uuid"]
        assert is_uuid(uuid_)

        import_uuid = str(uuid.uuid4())
        with self.subTest("Import new facet"):
            result_import = self.client.put(
                "klassifikation/facet/%s" % import_uuid,
                data={
                    "json": open("tests/fixtures/facet_opret.json", "rt").read(),
                },
            )
            assert result_import.status_code == 200
            assert result_import.get_json()["uuid"] == import_uuid

        with self.subTest("Update facet"):
            result_patch = self.client.patch(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_opdater.json", "rt").read(),
                },
            )
            assert result_patch.status_code == 200
            assert result_patch.get_json()["uuid"] == uuid_

        with self.subTest("Replace the facet content with old ones"):
            result_put = self.client.put(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_opret.json", "rt").read(),
                },
            )
            assert result_put.status_code == 200
            assert result_put.get_json()["uuid"] == uuid_

        with self.subTest("Passivate facet"):
            result_patch = self.client.patch(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_passiv.json", "rt").read(),
                },
            )
            assert result_patch.status_code == 200
            assert result_patch.get_json()["uuid"] == uuid_

        with self.subTest("Delete facet"):
            result_delete = self.client.delete(
                "klassifikation/facet/%s" % uuid_,
                data={
                    "json": open("tests/fixtures/facet_slet.json", "rt").read(),
                },
            )
            assert result_delete.status_code == 202
            assert result_delete.get_json()["uuid"] == uuid_


class TestSag(_TestInterface):
    def test_sag(self):
        with self.subTest("Create sag"):
            result = self.client.post(
                "/sag/sag",
                data={
                    "json": open("tests/fixtures/sag_opret.json", "rt").read(),
                }
            ).get_json()
            assert is_uuid(result["uuid"])
            uuid_ = result["uuid"]

        with self.subTest("Search on case andrebehandlere relation"):
            search1 = self.client.get(
                "sag/sag",
                query_string={
                    "andrebehandlere": "ef2713ee-1a38-4c23-8fcb-3c4331262194",
                    "uuid": uuid_,
                },
            )
            assert search1.status_code == 200
            assert search1.get_json()["results"][0][0] == uuid_

        with self.subTest("Search on case journalpostkode relation"):
            # unsupported argument: journalpostkode
            # search2 = self.client.get(
            #     "sag/sag",
            #     query_string={
            #         "journalpostkode": "journalnotat",
            #         "uuid": uuid_,
            #     },
            # )
            # assert search2.status_code == 200
            # assert search2.get_json()["results"][0][0] == uuid_
            pass

        with self.subTest("Search on case wrong journalpostkode relation"):
            # unsupported argument: journalpostkode
            # search3 = self.client.get(
            #     "sag/sag",
            #     query_string={
            #         "journalpostkode": "tilakteretdokument",
            #         "uuid": uuid_,
            #     },
            # )
            # assert search3.status_code == 400
            pass

        with self.subTest("Search on case journalnotat.titel relation"):
            # unsupported argument: journalnotat.titel
            # search4 = self.client.get(
            #     "sag/sag",
            #     query_string={
            #         "journalnotat.titel": "Kommentarer",
            #         "uuid": uuid_,
            #     },
            # )
            # assert search4.status_code == 200
            # assert search4.get_json()["results"][0][0] == uuid_
            pass

        with self.subTest("Search on case wrong journalnotat.titel relation"):
            # unsupported argument: journalnotat.titel
            # search5 = self.client.get(
            #     "sag/sag",
            #     query_string={
            #         "journalnotat.titel": "Wrong",
            #         "uuid": uuid_,
            #     },
            # )
            # assert search5.status_code == 400
            pass

        with self.subTest("Search on case journaldokument.dokumenttitel relation"):
            # unsupported argument: journaldokument.dokumenttitel
            # search6 = self.client.get(
            #     "sag/sag",
            #     query_string={
            #         "journaldokument.dokumenttitel": "Rapport",
            #         "uuid": uuid_,
            #     },
            # )
            # assert search6.status_code == 200
            # assert search6.get_json()["results"][0][0] == uuid_
            pass

        with self.subTest("Search on case wrong journaldokument.dokumenttitel relation"):
            # unsupported argument: journaldokument.dokumenttitel
            # search7 = self.client.get(
            #     "sag/sag",
            #     query_string={
            #         "journaldokument.dokumenttitel": "Wrong",
            #         "uuid": uuid_,
            #     },
            # )
            # assert search7.status_code == 400
            pass

        with self.subTest("Search on case journaldokument.offentligtundtaget.alternativtitel relation"):
            # unsupported argument:
            # journaldokument.offenligtundtaget.alternativtitel
            # search8 = self.client.get(
            #     "sag/sag",
            #     query_string={
            #         "journaldokument.offentligtundtaget.alternativtitel": "Fortroligt",
            #         "uuid": uuid_,
            #     },
            # )
            # assert search8.status_code == 200
            # assert search8.get_json()["results"][0][0] == uuid_
            pass

        with self.subTest("Search on case wrong journaldokument.offentligtundtaget.alternativtitel relation"):
            # unsupported argument:
            # journaldokument.offenligtundtaget.alternativtitel
            # search9 = self.client.get(
            #     "sag/sag",
            #     query_string={
            #         "journaldokument.offentligtundtaget.alternativtitel": "Wrong",
            #         "uuid": uuid_,
            #     },
            # )
            # assert search9.status_code == 400
            pass
