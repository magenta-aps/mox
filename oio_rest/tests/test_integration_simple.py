#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

from . import util

UUID_PATTERN = (
    "<regex(\"[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-"
    "[a-fA-F0-9]{4}-[a-fA-F0-9]{12}\"):uuid>"
)

CONTENT_PATH_PATTERN = (
    "<regex(\"\\d{4}/\\d{2}/\\d{2}/\\d{2}/\\d{2}/"
    "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-"
    "[a-fA-F0-9]{12}.bin\"):content_path>"
)


class Tests(util.TestCase):
    def test_site_map(self):
        self.assertRequestResponse(
            '/site-map',
            {
                "site-map": [
                    "/",
                    "/aktivitet/aktivitet",
                    "/aktivitet/aktivitet/" + UUID_PATTERN,
                    "/aktivitet/aktivitet/fields",
                    "/aktivitet/classes",
                    "/dokument/classes",
                    "/dokument/dokument",
                    "/dokument/dokument/" + UUID_PATTERN,
                    "/dokument/dokument/" + CONTENT_PATH_PATTERN,
                    "/dokument/dokument/fields",
                    "/get-token",
                    "/indsats/classes",
                    "/indsats/indsats",
                    "/indsats/indsats/" + UUID_PATTERN,
                    "/indsats/indsats/fields",
                    "/klassifikation/classes",
                    "/klassifikation/facet",
                    "/klassifikation/facet/" + UUID_PATTERN,
                    "/klassifikation/facet/fields",
                    "/klassifikation/klasse",
                    "/klassifikation/klasse/" + UUID_PATTERN,
                    "/klassifikation/klasse/fields",
                    "/klassifikation/klassifikation",
                    "/klassifikation/klassifikation/" + UUID_PATTERN,
                    "/klassifikation/klassifikation/fields",
                    "/log/classes",
                    "/log/loghaendelse",
                    "/log/loghaendelse/" + UUID_PATTERN,
                    "/log/loghaendelse/fields",
                    "/organisation/bruger",
                    "/organisation/bruger/" + UUID_PATTERN,
                    "/organisation/bruger/fields",
                    "/organisation/classes",
                    "/organisation/interessefaellesskab",
                    "/organisation/interessefaellesskab/" + UUID_PATTERN,
                    "/organisation/interessefaellesskab/fields",
                    "/organisation/itsystem",
                    "/organisation/itsystem/" + UUID_PATTERN,
                    "/organisation/itsystem/fields",
                    "/organisation/organisation",
                    "/organisation/organisation/" + UUID_PATTERN,
                    "/organisation/organisation/fields",
                    "/organisation/organisationenhed",
                    "/organisation/organisationenhed/" + UUID_PATTERN,
                    "/organisation/organisationenhed/fields",
                    "/organisation/organisationfunktion",
                    "/organisation/organisationfunktion/" + UUID_PATTERN,
                    "/organisation/organisationfunktion/fields",
                    "/sag/classes",
                    "/sag/sag",
                    "/sag/sag/" + UUID_PATTERN,
                    "/sag/sag/fields",
                    "/site-map",
                    "/static/<path:filename>",
                    "/tilstand/classes",
                    "/tilstand/tilstand",
                    "/tilstand/tilstand/" + UUID_PATTERN,
                    "/tilstand/tilstand/fields"
                ]
            }
        )

    def test_organisation(self):
        self.assertRequestResponse(
            '/organisation/organisation?bvn=%',
            {
                'results': [
                    [],
                ],
            },
        )

    def test_finding_nothing(self):
        endpoints = [
            endpoint.rsplit('/', 1)[0]
            for endpoint in self.client.get('/site-map').json['site-map']
            if endpoint.endswith(UUID_PATTERN)
        ]

        self.assertEquals(
            [
                '/aktivitet/aktivitet',
                '/dokument/dokument',
                '/indsats/indsats',
                '/klassifikation/facet',
                '/klassifikation/klasse',
                '/klassifikation/klassifikation',
                '/log/loghaendelse',
                '/organisation/bruger',
                '/organisation/interessefaellesskab',
                '/organisation/itsystem',
                '/organisation/organisation',
                '/organisation/organisationenhed',
                '/organisation/organisationfunktion',
                '/sag/sag',
                '/tilstand/tilstand',
            ],
            endpoints)

        for endpoint in endpoints:
            self.assertRequestResponse(
                endpoint + '?bvn=%',
                {
                    'results': [
                        [],
                    ],
                },
            )
