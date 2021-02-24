# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

import datetime
import dateutil
import json
import time
import uuid

from tests import util
from tests.util import DBTestCase


class Tests(DBTestCase):
    def test_import(self):
        objid = self.load_fixture("/aktivitet/aktivitet", "aktivitet_opret.json")

        expected = {
            "attributter": {
                "aktivitetegenskaber": [
                    {
                        "aktivitetnavn": "XYZ",
                        "beskrivelse": "Jogging",
                        "brugervendtnoegle": "JOGGING",
                        "formaal": "Ja",
                        "sluttidspunkt": "2016-05-19T16:02:32+02:00",
                        "starttidspunkt": "2014-05-19T14:02:32+02:00",
                        "tidsforbrug": "2:00:00",
                        "virkning": {
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-" "74fea841adae",
                            "aktoertypekode": "Bruger",
                            "from": "2014-05-19 12:02:32+02",
                            "from_included": True,
                            "to": "infinity",
                            "to_included": False,
                        },
                    },
                ],
            },
            "brugerref": "42c432e8-9c4a-11e6-9f62-873cf34a735f",
            "note": "Ny aktivitet",
            "livscykluskode": "Opstaaet",
            "relationer": {
                "ansvarlig": [
                    {
                        "aktoerattr": {
                            "accepteret": "foreloebigt",
                            "obligatorisk": "valgfri",
                            "repraesentation_uuid": "0e3ed41a-08f2-4967-"
                            "8689-dce625f93029",
                        },
                        "objekttype": "Bruger",
                        "uuid": "abcdeabd-c1b0-48c2-aef7-74fea841adae",
                        "virkning": {
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-" "74fea841adae",
                            "aktoertypekode": "Bruger",
                            "from": "2014-05-19 12:02:32+02",
                            "from_included": True,
                            "notetekst": "Nothing to see here!",
                            "to": "infinity",
                            "to_included": False,
                        },
                    },
                ],
                "deltager": [
                    {
                        "aktoerattr": {
                            "accepteret": "foreloebigt",
                            "obligatorisk": "valgfri",
                            "repraesentation_uuid": "0e3ed41a-08f2-4967-"
                            "8689-dce625f93029",
                        },
                        "indeks": 1,
                        "objekttype": "Bruger",
                        "uuid": "123deabd-c1b0-48c2-aef7-74fea841adae",
                        "virkning": {
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-" "74fea841adae",
                            "aktoertypekode": "Bruger",
                            "from": "2014-05-19 12:02:32+02",
                            "from_included": True,
                            "notetekst": "Nothing to see here!",
                            "to": "infinity",
                            "to_included": False,
                        },
                    },
                    {
                        "aktoerattr": {
                            "accepteret": "foreloebigt",
                            "obligatorisk": "valgfri",
                            "repraesentation_uuid": "0123d41a-08f2-4967-"
                            "8689-dce625f93029",
                        },
                        "indeks": 2,
                        "objekttype": "Bruger",
                        "uuid": "22345abd-c1b0-48c2-aef7-74fea841adae",
                        "virkning": {
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-" "74fea841adae",
                            "aktoertypekode": "Bruger",
                            "from": "2014-05-19 12:02:32+02",
                            "from_included": True,
                            "notetekst": "Nothing to see here!",
                            "to": "infinity",
                            "to_included": False,
                        },
                    },
                ],
            },
            "tilstande": {
                "aktivitetpubliceret": [
                    {
                        "publiceret": "Publiceret",
                        "virkning": {
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-" "74fea841adae",
                            "aktoertypekode": "Bruger",
                            "from": "2014-05-19 12:02:32+02",
                            "from_included": True,
                            "notetekst": "Nothing to see here!",
                            "to": "infinity",
                            "to_included": False,
                        },
                    },
                ],
                "aktivitetstatus": [
                    {
                        "status": "Aktiv",
                        "virkning": {
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-" "74fea841adae",
                            "aktoertypekode": "Bruger",
                            "from": "2014-05-19 12:02:32+02",
                            "from_included": True,
                            "notetekst": "Nothing to see here!",
                            "to": "infinity",
                            "to_included": False,
                        },
                    },
                ],
            },
        }

        self.assertQueryResponse("/aktivitet/aktivitet", expected, uuid=objid)

        self.assertQueryResponse("/aktivitet/aktivitet", [objid], bvn="%")

        self.assertQueryResponse(
            "/aktivitet/aktivitet",
            [objid],
            ansvarlig="abcdeabd-c1b0-48c2-aef7-74fea841adae",
        )

        self.assertQueryResponse(
            "/aktivitet/aktivitet",
            [objid],
            brugerref="42c432e8-9c4a-11e6-9f62-873cf34a735f",
        )

        self.assertQueryResponse(
            "/aktivitet/aktivitet",
            [],
            ansvarlig="00000000-0000-0000-0000-000000000000",
        )

        self.assertQueryResponse(
            "/aktivitet/aktivitet",
            [],
            brugerref="00000000-0000-0000-0000-000000000000",
        )

        self.assertQueryResponse(
            "/aktivitet/aktivitet",
            [objid],
            **{
                "ansvarlig:Bruger": "abcdeabd-c1b0-48c2-aef7-74fea841adae",
            },
        )

        self.assertQueryResponse(
            "/aktivitet/aktivitet",
            [],
            **{
                "ansvarlig:xxx": "abcdeabd-c1b0-48c2-aef7-74fea841adae",
            },
        )

        self.assertQueryResponse(
            "/aktivitet/aktivitet",
            [],
            **{
                "ansvarlig:Bruger": "00000000-0000-0000-0000-000000000000",
            },
        )

        self.assertRequestFails(
            "/aktivitet/aktivitet",
            400,
            query_string={
                "xxx:xxx": "00000000-0000-0000-0000-000000000000",
            },
        )

        self.assertRequestFails(
            "/aktivitet/aktivitet",
            400,
            query_string={
                "brugerref:xxx": "00000000-0000-0000-0000-000000000000",
            },
        )

    def test_edit(self):
        objid = self.load_fixture("/aktivitet/aktivitet", "aktivitet_opret.json")

        self.assertRequestResponse(
            "/aktivitet/aktivitet/{}".format(objid),
            {
                "uuid": objid,
            },
            json=util.get_fixture("aktivitet_opdater.json"),
            method="PATCH",
        )

        expected = {
            "attributter": {
                "aktivitetegenskaber": [
                    {
                        "aktivitetnavn": "XYZ",
                        "beskrivelse": "Jogging",
                        "brugervendtnoegle": "JOGGING",
                        "formaal": "Ja",
                        "sluttidspunkt": "2016-05-19T16:02:32+02:00",
                        "starttidspunkt": "2014-05-19T14:02:32+02:00",
                        "tidsforbrug": "0",
                        "virkning": {
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-" "74fea841adae",
                            "aktoertypekode": "Bruger",
                            "from": "2016-05-19 12:02:32+02",
                            "from_included": True,
                            "to": "infinity",
                            "to_included": False,
                        },
                    },
                ],
            },
            "livscykluskode": "Rettet",
            "note": "Opdatering",
            "relationer": {
                "ansvarlig": [
                    {
                        "objekttype": "Bruger",
                        "uuid": "abcdeabd-c1b0-48c2-aef7-74fea841adae",
                        "virkning": {
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-" "74fea841adae",
                            "aktoertypekode": "Bruger",
                            "from": "2016-05-19 12:02:32+02",
                            "from_included": True,
                            "notetekst": "Nothing to see here!",
                            "to": "infinity",
                            "to_included": False,
                        },
                    },
                ],
                "deltager": [
                    {
                        "aktoerattr": {
                            "accepteret": "foreloebigt",
                            "obligatorisk": "valgfri",
                            "repraesentation_uuid": "0e3ed41a-08f2-4967-8689-"
                            "dce625f93029",
                        },
                        "indeks": 1,
                        "objekttype": "Bruger",
                        "uuid": "123deabd-c1b0-48c2-aef7-74fea841adae",
                        "virkning": {
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-" "74fea841adae",
                            "aktoertypekode": "Bruger",
                            "from": "2014-05-19 12:02:32+02",
                            "from_included": True,
                            "notetekst": "Nothing to see here!",
                            "to": "infinity",
                            "to_included": False,
                        },
                    },
                    {
                        "aktoerattr": {
                            "accepteret": "foreloebigt",
                            "obligatorisk": "valgfri",
                            "repraesentation_uuid": "0123d41a-08f2-4967-8689-"
                            "dce625f93029",
                        },
                        "indeks": 2,
                        "objekttype": "Bruger",
                        "uuid": "22345abd-c1b0-48c2-aef7-74fea841adae",
                        "virkning": {
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-" "74fea841adae",
                            "aktoertypekode": "Bruger",
                            "from": "2014-05-19 12:02:32+02",
                            "from_included": True,
                            "notetekst": "Nothing to see here!",
                            "to": "infinity",
                            "to_included": False,
                        },
                    },
                ],
            },
            "tilstande": {
                "aktivitetpubliceret": [
                    {
                        "publiceret": "Publiceret",
                        "virkning": {
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-" "74fea841adae",
                            "aktoertypekode": "Bruger",
                            "from": "2014-05-19 12:02:32+02",
                            "from_included": True,
                            "notetekst": "Nothing to see here!",
                            "to": "infinity",
                            "to_included": False,
                        },
                    },
                ],
                "aktivitetstatus": [
                    {
                        "status": "Aktiv",
                        "virkning": {
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-" "74fea841adae",
                            "aktoertypekode": "Bruger",
                            "from": "2014-05-19 12:02:32+02",
                            "from_included": True,
                            "notetekst": "Nothing to see here!",
                            "to": "infinity",
                            "to_included": False,
                        },
                    },
                ],
            },
        }

        self.assertQueryResponse(
            "/aktivitet/aktivitet",
            expected,
            uuid=objid,
        )

    def test_deleting_nothing(self):
        msg = "No Aktivitet with ID 00000000-0000-0000-0000-000000000000 found."

        self.assertRequestResponse(
            "/aktivitet/aktivitet" "/00000000-0000-0000-0000-000000000000",
            {
                "message": msg,
            },
            method="DELETE",
            status_code=404,
        )

    def test_deleting_something(self):
        objid = self.load_fixture("/aktivitet/aktivitet", "aktivitet_opret.json")

        r = self.client.delete(
            "/aktivitet/aktivitet/" + objid,
        )

        self.assertEqual(r.status_code, 202)
        self.assertEqual(r.status, "202 ACCEPTED")
        self.assertEqual(r.json, {"uuid": objid})

        # once more for prince canut!
        self.assertRequestResponse(
            "/aktivitet/aktivitet/" + objid,
            {
                "uuid": objid,
            },
            status_code=202,
            method="DELETE",
        )

    def test_searching(self):
        objid = self.load_fixture("/aktivitet/aktivitet", "aktivitet_opret.json")

        self.assertRequestResponse(
            "/aktivitet/aktivitet/{}".format(objid),
            {
                "uuid": objid,
            },
            json=util.get_fixture("aktivitet_opdater.json"),
            method="PATCH",
        )

        expected_found = {
            "results": [
                [
                    objid,
                ],
            ],
        }

        expected_nothing = {
            "results": [
                [],
            ],
        }

        self.assertRequestResponse(
            "aktivitet/aktivitet?bvn=JOGGING",
            expected_found,
        )

        self.assertRequestResponse(
            "aktivitet/aktivitet?bvn=JOGGING&status=Aktiv",
            expected_found,
        )

        self.assertRequestFails(
            "aktivitet/aktivitet?bvn=JOGGING&gyldighed=Aktiv",
            400,
        )

        self.assertRequestResponse(
            "aktivitet/aktivitet?bvn=JOGGING&status=Aktiv&foersteresultat=0",
            expected_found,
        )

        self.assertRequestResponse(
            "aktivitet/aktivitet?bvn=JOGGING&status=Inaktiv",
            expected_nothing,
        )

        self.assertRequestResponse(
            "aktivitet/aktivitet?bvn=JOGGING&status=Inaktiv",
            expected_nothing,
        )

        self.assertRequestResponse(
            "aktivitet/aktivitet?bvn=JOGGING&maximalantalresultater=0",
            expected_nothing,
        )

    def test_searching_with_limit(self):
        objid = self.load_fixture("/aktivitet/aktivitet", "aktivitet_opret.json")

        self.assertRequestResponse(
            "/aktivitet/aktivitet/{}".format(objid),
            {
                "uuid": objid,
            },
            json=util.get_fixture("aktivitet_opdater.json"),
            method="PATCH",
        )

        self.assertRequestResponse(
            "aktivitet/aktivitet?bvn=JOGGING&maximalantalresultater=2000",
            {
                "results": [
                    [
                        objid,
                    ],
                ],
            },
        )

        self.assertRequestResponse(
            "aktivitet/aktivitet?bvn=JOGGING&status=Aktiv&foersteresultat=1",
            {
                "results": [
                    [],
                ],
            },
        )

    def test_searching_with_limit_after_editing_bvn(self):
        objid = self.load_fixture("/aktivitet/aktivitet", "aktivitet_opret.json")

        self.assertRequestResponse(
            "/aktivitet/aktivitet/{}".format(objid),
            {
                "uuid": objid,
            },
            json=util.get_fixture("aktivitet_opdater.json"),
            method="PATCH",
        )

        self.assertRequestResponse(
            "/aktivitet/aktivitet/{}".format(objid),
            {
                "uuid": objid,
            },
            json={
                "note": "Ret BVN",
                "attributter": {
                    "aktivitetegenskaber": [
                        {
                            "brugervendtnoegle": "JOGGINGLØB",
                            "virkning": {
                                "from": "2017-01-01 00:00:00",
                                "to": "infinity",
                            },
                        },
                    ],
                },
            },
            method="PATCH",
        )

        self.assertRequestResponse(
            "aktivitet/aktivitet?bvn=JOG%&maximalantalresultater=2000",
            {
                "results": [
                    [
                        objid,
                    ],
                ],
            },
        )

        self.assertRequestResponse(
            "aktivitet/aktivitet?bvn=JOG%&status=Aktiv&foersteresultat=1",
            {
                "results": [
                    [],
                ],
            },
        )

    def test_searching_temporal_order(self):
        objids = [str(uuid.UUID(int=i)) for i in range(3)]

        tz = dateutil.tz.gettz("Europe/Copenhagen")
        no_time = datetime.datetime.now(tz).replace(tzinfo=None)

        time.sleep(0.01)

        for objid in objids:
            self.load_fixture("/aktivitet/aktivitet", "aktivitet_opret.json", objid)

        # the two are the same so we expect them to be ordered by UUID
        self.assertRequestResponse(
            "/aktivitet/aktivitet/?bvn=%&maximalantalresultater=10",
            {
                "results": [objids],
            },
        )

        time.sleep(0.01)

        exists_time = datetime.datetime.now(tz).replace(tzinfo=None)

        time.sleep(0.01)

        self.assertRequestResponse(
            "/aktivitet/aktivitet/{}".format(objids[1]),
            {
                "uuid": objids[1],
            },
            json={
                "note": "Ret BVN",
                "attributter": {
                    "aktivitetegenskaber": [
                        {
                            "brugervendtnoegle": "TESTFÆTTER",
                            "virkning": {
                                "from": "2017-01-01 00:00:00",
                                "to": "infinity",
                            },
                        },
                        {
                            "brugervendtnoegle": "ABEKAT",
                            "virkning": {
                                "from": "2015-01-01 00:00:00",
                                "to": "2017-01-01 00:00:00",
                            },
                        },
                    ],
                },
            },
            method="PATCH",
        )

        time.sleep(0.01)

        self.assertRequestResponse(
            "/aktivitet/aktivitet/?bvn=%&maximalantalresultater=10",
            {
                "results": [
                    [
                        objids[0],
                        objids[2],
                        objids[1],
                    ]
                ],
            },
        )

        self.assertRequestResponse(
            "/aktivitet/aktivitet/?bvn=%&maximalantalresultater=10"
            "&virkningstid=2016-01-01",
            {
                "results": [
                    [
                        objids[1],
                        objids[0],
                        objids[2],
                    ]
                ],
            },
        )

        self.assertRequestResponse(
            "/aktivitet/aktivitet/?bvn=%&maximalantalresultater=10"
            "&registreringstid=" + exists_time.isoformat(),
            {
                "results": [objids],
            },
        )

        self.assertRequestResponse(
            "/aktivitet/aktivitet/?bvn=%&maximalantalresultater=10"
            "&registreringstid=" + no_time.isoformat(),
            {
                "results": [[]],
            },
        )

    def test_search_list(self):
        # test search and retrieve #27508
        objids = [str(uuid.UUID(int=i)) for i in range(3)]

        for objid in objids:
            self.load_fixture(
                "/aktivitet/aktivitet",
                "aktivitet_opret.json",
                objid,
            )

        request = self.perform_request("/aktivitet/aktivitet/?bvn=%&list")
        results = json.loads(request.get_data(as_text=True))

        for r in results["results"]:
            self.assertIn(r[0]["id"], objids)

        self.assertEqual(len(results["results"][0]), len(objids))
