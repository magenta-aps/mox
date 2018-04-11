#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

import json
import re

from . import util


UUID_REGEX = re.compile('[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-'
                        '[a-fA-F0-9]{4}-[a-fA-F0-9]{12}')


class TestAttributesCreateOrganisation(util.TestCase):

    def setUp(self):
        super(TestAttributesCreateOrganisation, self).setUp()
        self.STANDARD_VIRKNING = {
            u"from": u"2000-01-01 12:00:00+01",
            u"from_included": True,
            u"to": u"2020-01-01 12:00:00+01",
            u"to_included": False
        }
        self.ORG = {
            u"attributter": {
                u"organisationegenskaber": [
                    {
                        u"brugervendtnoegle": u"bvn1",
                        u"organisationsnavn": u"orgName1",
                        u"virkning": self.STANDARD_VIRKNING
                    }
                ]
            },
            u"tilstande": {
                u"organisationgyldighed": [
                    {
                        u"gyldighed": u"Aktiv",
                        u"virkning": self.STANDARD_VIRKNING
                    }
                ]
            },
        }

    def test_nonote_validbvn_noorgname_validvirkning(self):
        """
        Equivalence classes covered: [2][6][9][13]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation

        self.ORG['attributter']['organisationegenskaber'][0].pop(
            'organisationsnavn')

        r = self.client.post(
            '/organisation/organisation',
            data=json.dumps(self.ORG),
            content_type='application/json'
        )

        # Check response

        self.assertEquals(201, r.status_code)
        self.assertEquals(1, len(r.json))
        self.assertTrue(UUID_REGEX.match(r.json['uuid']))

        # Check persisted data

        self.ORG['livscykluskode'] = 'Opstaaet'

        self.assertQueryResponse(
            self.ORG,
            '/organisation/organisation', uuid=r.json['uuid']
        )