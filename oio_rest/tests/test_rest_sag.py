# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import unittest
import uuid

from oio_rest.utils.build_registration import is_uuid
from tests import util


class TestSag(util.TestCase):
    @unittest.expectedFailure
    def test_sag(self):
        with self.subTest("Create sag"):
            result = self.client.post(
                "/sag/sag",
                data={
                    "json": open("tests/fixtures/sag_opret.json", "rt").read(),
                }
            ).get_json()
            self.assertTrue(is_uuid(result["uuid"]))
            uuid_ = result["uuid"]

        with self.subTest("Search on case andrebehandlere relation"):
            search1 = self.client.get(
                "sag/sag",
                query_string={
                    "andrebehandlere": "ef2713ee-1a38-4c23-8fcb-3c4331262194",
                    "uuid": uuid_,
                },
            )
            self.assertEqual(search1.status_code, 200)
            self.assertEqual(search1.get_json()["results"][0][0], uuid_)

        with self.subTest("Search on case journalpostkode relation"):
            # unsupported argument: journalpostkode
            search2 = self.client.get(
                "sag/sag",
                query_string={
                    "journalpostkode": "journalnotat",
                    "uuid": uuid_,
                },
            )
            self.assertEqual(search2.status_code, 200)
            self.assertEqual(search2.get_json()["results"][0][0], uuid_)

        with self.subTest("Search on case wrong journalpostkode relation"):
            # unsupported argument: journalpostkode
            search3 = self.client.get(
                "sag/sag",
                query_string={
                    "journalpostkode": "tilakteretdokument",
                    "uuid": uuid_,
                },
            )
            self.assertEqual(search3.status_code, 400)

        with self.subTest("Search on case journalnotat.titel relation"):
            # unsupported argument: journalnotat.titel
            search4 = self.client.get(
                "sag/sag",
                query_string={
                    "journalnotat.titel": "Kommentarer",
                    "uuid": uuid_,
                },
            )
            self.assertEqual(search4.status_code, 200)
            self.assertEqual(search4.get_json()["results"][0][0], uuid_)

        with self.subTest("Search on case wrong journalnotat.titel relation"):
            # unsupported argument: journalnotat.titel
            search5 = self.client.get(
                "sag/sag",
                query_string={
                    "journalnotat.titel": "Wrong",
                    "uuid": uuid_,
                },
            )
            self.assertEqual(search5.status_code, 400)

        with self.subTest("Search on case journaldokument.dokumenttitel relation"):
            # unsupported argument: journaldokument.dokumenttitel
            search6 = self.client.get(
                "sag/sag",
                query_string={
                    "journaldokument.dokumenttitel": "Rapport",
                    "uuid": uuid_,
                },
            )
            self.assertEqual(search6.status_code, 200)
            self.assertEqual(search6.get_json()["results"][0][0], uuid_)

        with self.subTest("Search on case wrong journaldokument.dokumenttitel relation"):
            # unsupported argument: journaldokument.dokumenttitel
            search7 = self.client.get(
                "sag/sag",
                query_string={
                    "journaldokument.dokumenttitel": "Wrong",
                    "uuid": uuid_,
                },
            )
            self.assertEqual(search7.status_code, 400)

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
            self.assertEqual(search8.status_code, 200)
            self.assertEqual(search8.get_json()["results"][0][0], uuid_)

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
            self.assertEqual(search9.status_code, 400)
