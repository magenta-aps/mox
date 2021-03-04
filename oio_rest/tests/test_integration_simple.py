# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from tests.util import DBTestCase


UUID_PATTERN = "{uuid}"
CONTENT_PATH_PATTERN = "{content_path}"


class Tests(DBTestCase):
    def test_site_map(self):
        self.assertRequestResponse(
            "/site-map",
            {
                "site-map": [
                    "/",
                    "/aktivitet/aktivitet",
                    "/aktivitet/aktivitet/fields",
                    "/aktivitet/aktivitet/schema",
                    "/aktivitet/aktivitet/" + UUID_PATTERN,
                    "/aktivitet/classes",
                    "/docs",
                    "/docs/oauth2-redirect",
                    "/dokument/classes",
                    "/dokument/dokument",
                    "/dokument/dokument/fields",
                    "/dokument/dokument/schema",
                    "/dokument/dokument/" + CONTENT_PATH_PATTERN,
                    "/dokument/dokument/" + UUID_PATTERN,
                    "/indsats/classes",
                    "/indsats/indsats",
                    "/indsats/indsats/fields",
                    "/indsats/indsats/schema",
                    "/indsats/indsats/" + UUID_PATTERN,
                    "/klassifikation/classes",
                    "/klassifikation/facet",
                    "/klassifikation/facet/fields",
                    "/klassifikation/facet/schema",
                    "/klassifikation/facet/" + UUID_PATTERN,
                    "/klassifikation/klasse",
                    "/klassifikation/klasse/fields",
                    "/klassifikation/klasse/schema",
                    "/klassifikation/klasse/" + UUID_PATTERN,
                    "/klassifikation/klassifikation",
                    "/klassifikation/klassifikation/fields",
                    "/klassifikation/klassifikation/schema",
                    "/klassifikation/klassifikation/" + UUID_PATTERN,
                    "/log/classes",
                    "/log/loghaendelse",
                    "/log/loghaendelse/fields",
                    "/log/loghaendelse/schema",
                    "/log/loghaendelse/" + UUID_PATTERN,
                    "/openapi.json",
                    "/organisation/bruger",
                    "/organisation/bruger/fields",
                    "/organisation/bruger/schema",
                    "/organisation/bruger/" + UUID_PATTERN,
                    "/organisation/classes",
                    "/organisation/interessefaellesskab",
                    "/organisation/interessefaellesskab/fields",
                    "/organisation/interessefaellesskab/schema",
                    "/organisation/interessefaellesskab/" + UUID_PATTERN,
                    "/organisation/itsystem",
                    "/organisation/itsystem/fields",
                    "/organisation/itsystem/schema",
                    "/organisation/itsystem/" + UUID_PATTERN,
                    "/organisation/organisation",
                    "/organisation/organisation/fields",
                    "/organisation/organisation/schema",
                    "/organisation/organisation/" + UUID_PATTERN,
                    "/organisation/organisationenhed",
                    "/organisation/organisationenhed/fields",
                    "/organisation/organisationenhed/schema",
                    "/organisation/organisationenhed/" + UUID_PATTERN,
                    "/organisation/organisationfunktion",
                    "/organisation/organisationfunktion/fields",
                    "/organisation/organisationfunktion/schema",
                    "/organisation/organisationfunktion/" + UUID_PATTERN,
                    "/redoc",
                    "/sag/classes",
                    "/sag/sag",
                    "/sag/sag/fields",
                    "/sag/sag/schema",
                    "/sag/sag/" + UUID_PATTERN,
                    "/site-map",
                    "/tilstand/classes",
                    "/tilstand/tilstand",
                    "/tilstand/tilstand/fields",
                    "/tilstand/tilstand/schema",
                    "/tilstand/tilstand/" + UUID_PATTERN,
                    "/version",
                ]
            },
            method="GET"
        )

    def test_organisation(self):
        self.assertRequestResponse(
            "/organisation/organisation?bvn=%",
            {
                "results": [
                    [],
                ],
            },
        )

    def test_log_has_no_bvn(self):
        self.assertRequestFails(
            "/log/loghaendelse?bvn=%",
            400,
        )

    def test_finding_nothing(self):
        endpoints = [
            endpoint.rsplit("/", 1)[0]
            for endpoint in self.client.get("/site-map").json()["site-map"]
            if endpoint.endswith(UUID_PATTERN)
        ]

        self.assertEqual(
            [
                "/aktivitet/aktivitet",
                "/dokument/dokument",
                "/indsats/indsats",
                "/klassifikation/facet",
                "/klassifikation/klasse",
                "/klassifikation/klassifikation",
                "/log/loghaendelse",
                "/organisation/bruger",
                "/organisation/interessefaellesskab",
                "/organisation/itsystem",
                "/organisation/organisation",
                "/organisation/organisationenhed",
                "/organisation/organisationfunktion",
                "/sag/sag",
                "/tilstand/tilstand",
            ],
            endpoints,
        )

        for endpoint in endpoints:
            if endpoint == "/log/loghaendelse":
                req = endpoint + "?note=%"
            else:
                req = endpoint + "?bvn=%"

            with self.subTest(req):
                self.assertRequestResponse(
                    req,
                    {
                        "results": [
                            [],
                        ],
                    },
                )
