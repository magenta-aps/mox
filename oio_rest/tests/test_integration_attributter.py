#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

import json
import re
import unittest

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

    def _post(self, payload):
        """
        Make HTTP POST request to /organisation/organisation
        :param payload: dictionary containing payload to LoRa
        :return: Response from LoRa
        """
        r = self.client.post(
            '/organisation/organisation',
            data=json.dumps(payload),
            content_type='application/json'
        )
        return r

    def _check_response_201(self, response):
        """
        Verify that the response from LoRa is 201 and contains the correct
        JSON.
        :param response: Response from LoRa when creating a new organisation
        """
        self.assertEquals(201, response.status_code)
        self.assertEquals(1, len(response.json))
        self.assertTrue(UUID_REGEX.match(response.json['uuid']))

    def test_noNote_validBvn_noOrgName_validVirkning(self):
        """
        Equivalence classes covered: [2][6][9][13]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation

        del self.ORG['attributter']['organisationegenskaber'][0][
            'organisationsnavn']

        r = self._post(self.ORG)

        # Check response

        self._check_response_201(r)

        # Check persisted data

        self.ORG['livscykluskode'] = 'Opstaaet'

        self.assertQueryResponse(
            self.ORG,
            '/organisation/organisation', uuid=r.json['uuid']
        )

    def test_validNote_validOrgName_twoOrgEgenskaber(self):
        """
        Equivalence classes covered: [3][10][15]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation

        self.ORG[u'note'] = u'This is a note'
        self.ORG['attributter']['organisationegenskaber'].append(
            {
                u"brugervendtnoegle": u"bnv2",
                u"organisationsnavn": u"orgName2",
                u"virkning": {
                    u"from": u"2020-01-01 12:00:00+01",
                    u"from_included": True,
                    u"to": u"2030-01-01 12:00:00+01",
                    u"to_included": False
                }
            }
        )

        r = self._post(self.ORG)

        # Check response

        self._check_response_201(r)

        # Check persisted data

        self.ORG['livscykluskode'] = 'Opstaaet'

        self.assertQueryResponse(
            self.ORG,
            '/organisation/organisation',
            uuid=r.json['uuid'],
            virkningfra='-infinity',
            virkningtil='infinity'
        )

    def test_invalidNote(self):
        """
        Equivalence classes covered: [1]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.ORG[u'note'] = ['Note cannot be e.g. a list']

        self.assertRequestFails(
            '/organisation/organisation',
            400,
            json=self.ORG
        )

    @unittest.expectedFailure
    def test_bvnMissing(self):
        """
        Equivalence classes covered: [4]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation

        del self.ORG['attributter']['organisationegenskaber'][0][
            'brugervendtnoegle']

        self.assertRequestFails(
            '/organisation/organisation',
            400,
            json=self.ORG
        )
