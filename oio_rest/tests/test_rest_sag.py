# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import unittest

from oio_rest.utils.build_registration import is_uuid
from tests import util
from tests.util import DBTestCase


class TestSag(DBTestCase):
    def setUp(self):
        super().setUp()

        result = self.client.post(
            "/sag/sag",
            json=util.get_fixture("sag_opret.json"),
        ).get_json()
        self.assertTrue(is_uuid(result["uuid"]))
        self.uuid = result["uuid"]

    def test_sag_1(self):
        "Search for andrebehandlere relation"
        search1 = self.client.get(
            "sag/sag",
            query_string={
                "andrebehandlere": "ef2713ee-1a38-4c23-8fcb-3c4331262194",
                "uuid": self.uuid,
            },
        )
        self.assertEqual(search1.status_code, 200)
        self.assertEqual(search1.get_json()["results"][0][0], self.uuid)

    @unittest.expectedFailure
    def test_sag_2(self):
        "Search for journalpostkode relation"
        # unsupported argument: journalpostkode
        search2 = self.client.get(
            "sag/sag",
            query_string={
                "journalpostkode": "journalnotat",
                "uuid": self.uuid,
            },
        )
        self.assertEqual(search2.status_code, 200)
        self.assertEqual(search2.get_json()["results"][0][0], self.uuid)

    def test_sag_3(self):
        "Search for wrong journalpostkode relation"
        # unsupported argument: journalpostkode
        search3 = self.client.get(
            "sag/sag",
            query_string={
                "journalpostkode": "tilakteretdokument",
                "uuid": self.uuid,
            },
        )
        self.assertEqual(search3.status_code, 400)

    @unittest.expectedFailure
    def test_sag_4(self):
        "Search for journalnotat.titel relation"
        # unsupported argument: journalnotat.titel
        search4 = self.client.get(
            "sag/sag",
            query_string={
                "journalnotat.titel": "Kommentarer",
                "uuid": self.uuid,
            },
        )
        self.assertEqual(search4.status_code, 200)
        self.assertEqual(search4.get_json()["results"][0][0], self.uuid)

    def test_sag_5(self):
        "Search for wrong journalnotat.titel relation"
        # unsupported argument: journalnotat.titel
        search5 = self.client.get(
            "sag/sag",
            query_string={
                "journalnotat.titel": "Wrong",
                "uuid": self.uuid,
            },
        )
        self.assertEqual(search5.status_code, 400)

    @unittest.expectedFailure
    def test_sag_6(self):
        "Search for journaldokument.dokumenttitel relation"
        # unsupported argument: journaldokument.dokumenttitel
        search6 = self.client.get(
            "sag/sag",
            query_string={
                "journaldokument.dokumenttitel": "Rapport",
                "uuid": self.uuid,
            },
        )
        self.assertEqual(search6.status_code, 200)
        self.assertEqual(search6.get_json()["results"][0][0], self.uuid)

    def test_sag_7(self):
        "Search for wrong journaldokument.dokumenttitel relation"
        # unsupported argument: journaldokument.dokumenttitel
        search7 = self.client.get(
            "sag/sag",
            query_string={
                "journaldokument.dokumenttitel": "Wrong",
                "uuid": self.uuid,
            },
        )
        self.assertEqual(search7.status_code, 400)

    @unittest.expectedFailure
    def test_sag_8(self):
        "Search journaldokument.offentligtundtaget.alternativtitel relation"
        # unsupported argument:
        # journaldokument.offenligtundtaget.alternativtitel
        search8 = self.client.get(
            "sag/sag",
            query_string={
                "journaldokument.offentligtundtaget.alternativtitel":
                "Fortroligt", "uuid": self.uuid,
            },
        )
        self.assertEqual(search8.status_code, 200)
        self.assertEqual(search8.get_json()["results"][0][0], self.uuid)

    def test_sag_9(self):
        "Wrong journaldokument.offentligtundtaget.alternativtitel relation"
        # unsupported argument:
        # journaldokument.offenligtundtaget.alternativtitel
        search9 = self.client.get(
            "sag/sag",
            query_string={
                "journaldokument.offentligtundtaget.alternativtitel": "Wrong",
                "uuid": self.uuid,
            },
        )
        self.assertEqual(search9.status_code, 400)
