#
# Copyright (c) 2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

import copy
import json
import unittest

from . import util


def mkuuid(n: int):
    return "00000000-0000-0000-0000-{:012d}".format(n)


class Tests(util.TestCase):
    def setUp(self):
        super().setUp()

        self.path = '/organisation/organisation'

    def make_org(self, num: int, valid: bool=True):
        nums = str(num)
        effect = {
            "from": "2000-01-01",
            "to": "infinity",
        }

        obj = {
            "attributter": {
                "organisationegenskaber": [
                    {
                        "brugervendtnoegle": "unit" + nums,
                        "organisationsnavn": "unit" + nums,
                        "virkning": effect,
                    },
                ],
            },
            "relationer": {
                'ansatte': [
                    {
                        "uuid": mkuuid(num),
                        "virkning": effect,
                    },
                    {
                        "urn": "urn:" + nums,
                        "virkning": effect,
                    }
                ]
            },
            "tilstande": {
                "organisationgyldighed": [
                    {
                        "gyldighed": "Aktiv" if valid else "Inaktiv",
                        "virkning": effect,
                    },
                ],
            },
        }

        #print(json.dumps(obj, indent=2))

        r = self.perform_request(self.path, json=obj)
        self.assert201(r)

    def check(self, query_string, n):
        with self.subTest('{!r} - {}'.format(query_string, n)):
            r1 = self.perform_request(self.path,
                                      query_string=query_string)
            self.assert200(r1)

            r2 = self.perform_request(self.path,
                                      query_string=query_string + '&count=1')
            self.assert200(r2)

            self.assertEqual(
                len(r1.json['results'][0]),
                r2.json['results'][0],
            )

            self.assertEqual(n, r2.json['results'][0])

    def test_counting(self):
        for i in range(0, 50, 5):
            self.make_org(i, i % 10)

        self.check('bvn=%', 10)
        self.check('bvn=a%', 0)
        self.check('bvn=unit%', 10)
        self.check('bvn=unit1%', 2)
        self.check('bvn=unit10', 1)
        self.check('bvn=unit10&organisationsnavn=unit10', 1)
        self.check('bvn=unit%&organisationsnavn=unit%', 10)
        self.check('bvn=unit1%&organisationsnavn=unit1%', 2)
        self.check('bvn=unit1%&organisationsnavn=unit10', 1)
        self.check('bvn=unit10&organisationsnavn=unit1%', 1)
        self.check('bvn=unit10&organisationsnavn=unit10', 1)
        self.check('bvn=unit10&organisationsnavn=unit15', 0)

        self.check('gyldighed=Aktiv', 5)

        self.check('bvn=unit1%&gyldighed=Aktiv', 1)

        self.check('ansatte=00000000-0000-0000-0000-000000000010',
                   1)
        self.check('bvn=unit1%&ansatte=00000000-0000-0000-0000-000000000010',
                   1)
        self.check('bvn=unit1%&gyldighed=Aktiv&ansatte=urn:15', 1)
        self.check('bvn=unit1%&gyldighed=Inaktiv&ansatte=urn:15', 0)
        self.check('bvn=unit1%&ansatte=urn:10', 1)
        self.check('bvn=unit1%&ansatte=urn:10&ansatte=urn:15', 0)
        self.check('bvn=unit1%&gyldighed=Aktiv&ansatte=urn:10&ansatte=urn:15', 0)
