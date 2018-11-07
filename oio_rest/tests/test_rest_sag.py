import unittest
import uuid

from oio_rest.utils import test_support
from oio_rest.utils.build_registration import is_uuid


class TestSag(test_support.TestRestInterface):
    @unittest.expectedFailure
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
            search2 = self.client.get(
                "sag/sag",
                query_string={
                    "journalpostkode": "journalnotat",
                    "uuid": uuid_,
                },
            )
            assert search2.status_code == 200
            assert search2.get_json()["results"][0][0] == uuid_

        with self.subTest("Search on case wrong journalpostkode relation"):
            # unsupported argument: journalpostkode
            search3 = self.client.get(
                "sag/sag",
                query_string={
                    "journalpostkode": "tilakteretdokument",
                    "uuid": uuid_,
                },
            )
            assert search3.status_code == 400

        with self.subTest("Search on case journalnotat.titel relation"):
            # unsupported argument: journalnotat.titel
            search4 = self.client.get(
                "sag/sag",
                query_string={
                    "journalnotat.titel": "Kommentarer",
                    "uuid": uuid_,
                },
            )
            assert search4.status_code == 200
            assert search4.get_json()["results"][0][0] == uuid_

        with self.subTest("Search on case wrong journalnotat.titel relation"):
            # unsupported argument: journalnotat.titel
            search5 = self.client.get(
                "sag/sag",
                query_string={
                    "journalnotat.titel": "Wrong",
                    "uuid": uuid_,
                },
            )
            assert search5.status_code == 400

        with self.subTest("Search on case journaldokument.dokumenttitel relation"):
            # unsupported argument: journaldokument.dokumenttitel
            search6 = self.client.get(
                "sag/sag",
                query_string={
                    "journaldokument.dokumenttitel": "Rapport",
                    "uuid": uuid_,
                },
            )
            assert search6.status_code == 200
            assert search6.get_json()["results"][0][0] == uuid_

        with self.subTest("Search on case wrong journaldokument.dokumenttitel relation"):
            # unsupported argument: journaldokument.dokumenttitel
            search7 = self.client.get(
                "sag/sag",
                query_string={
                    "journaldokument.dokumenttitel": "Wrong",
                    "uuid": uuid_,
                },
            )
            assert search7.status_code == 400

        with self.subTest("Search on case journaldokument.offentligtundtaget.alternativtitel relation"):
            # unsupported argument:
            # journaldokument.offenligtundtaget.alternativtitel
            search8 = self.client.get(
                "sag/sag",
                query_string={
                    "journaldokument.offentligtundtaget.alternativtitel": "Fortroligt",
                    "uuid": uuid_,
                },
            )
            assert search8.status_code == 200
            assert search8.get_json()["results"][0][0] == uuid_

        with self.subTest("Search on case wrong journaldokument.offentligtundtaget.alternativtitel relation"):
            # unsupported argument:
            # journaldokument.offenligtundtaget.alternativtitel
            search9 = self.client.get(
                "sag/sag",
                query_string={
                    "journaldokument.offentligtundtaget.alternativtitel": "Wrong",
                    "uuid": uuid_,
                },
            )
            assert search9.status_code == 400
