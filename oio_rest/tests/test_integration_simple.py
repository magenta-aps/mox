# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from tests.util import DBTestCase


UUID_PATTERN = '{uuid}'

CONTENT_PATH_PATTERN = (
    '<regex("\\d{4}/\\d{2}/\\d{2}/\\d{2}/\\d{2}/'
    "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-"
    '[a-fA-F0-9]{12}.bin"):content_path>'
)


class Tests(DBTestCase):
    def test_site_map(self):
        self.assertRequestResponse(
            "/site-map",
            {
                "site-map": [
                    "/",
                    "/aktivitet/aktivitet",
                    "/aktivitet/aktivitet/" + UUID_PATTERN,
                    "/aktivitet/aktivitet/fields",
                    "/aktivitet/aktivitet/schema",
                    "/aktivitet/classes",
                    "/dokument/classes",
                    "/dokument/dokument",
                    "/dokument/dokument/" + UUID_PATTERN,
                    "/dokument/dokument/" + CONTENT_PATH_PATTERN,
                    "/dokument/dokument/fields",
                    "/dokument/dokument/schema",
                    "/indsats/classes",
                    "/indsats/indsats",
                    "/indsats/indsats/" + UUID_PATTERN,
                    "/indsats/indsats/fields",
                    "/indsats/indsats/schema",
                    "/klassifikation/classes",
                    "/klassifikation/facet",
                    "/klassifikation/facet/" + UUID_PATTERN,
                    "/klassifikation/facet/fields",
                    "/klassifikation/facet/schema",
                    "/klassifikation/klasse",
                    "/klassifikation/klasse/" + UUID_PATTERN,
                    "/klassifikation/klasse/fields",
                    "/klassifikation/klasse/schema",
                    "/klassifikation/klassifikation",
                    "/klassifikation/klassifikation/" + UUID_PATTERN,
                    "/klassifikation/klassifikation/fields",
                    "/klassifikation/klassifikation/schema",
                    "/log/classes",
                    "/log/loghaendelse",
                    "/log/loghaendelse/" + UUID_PATTERN,
                    "/log/loghaendelse/fields",
                    "/log/loghaendelse/schema",
                    "/organisation/bruger",
                    "/organisation/bruger/" + UUID_PATTERN,
                    "/organisation/bruger/fields",
                    "/organisation/bruger/schema",
                    "/organisation/classes",
                    "/organisation/interessefaellesskab",
                    "/organisation/interessefaellesskab/" + UUID_PATTERN,
                    "/organisation/interessefaellesskab/fields",
                    "/organisation/interessefaellesskab/schema",
                    "/organisation/itsystem",
                    "/organisation/itsystem/" + UUID_PATTERN,
                    "/organisation/itsystem/fields",
                    "/organisation/itsystem/schema",
                    "/organisation/organisation",
                    "/organisation/organisation/" + UUID_PATTERN,
                    "/organisation/organisation/fields",
                    "/organisation/organisation/schema",
                    "/organisation/organisationenhed",
                    "/organisation/organisationenhed/" + UUID_PATTERN,
                    "/organisation/organisationenhed/fields",
                    "/organisation/organisationenhed/schema",
                    "/organisation/organisationfunktion",
                    "/organisation/organisationfunktion/" + UUID_PATTERN,
                    "/organisation/organisationfunktion/fields",
                    "/organisation/organisationfunktion/schema",
                    "/sag/classes",
                    "/sag/sag",
                    "/sag/sag/" + UUID_PATTERN,
                    "/sag/sag/fields",
                    "/sag/sag/schema",
                    "/site-map",
                    "/static/<path:filename>",
                    "/tilstand/classes",
                    "/tilstand/tilstand",
                    "/tilstand/tilstand/" + UUID_PATTERN,
                    "/tilstand/tilstand/fields",
                    "/tilstand/tilstand/schema",
                    "/version",
                ]
            },
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
            for endpoint in self.client.get("/site-map").json["site-map"]
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
