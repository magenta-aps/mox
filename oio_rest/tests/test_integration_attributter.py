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


class TestCreateOrganisation(util.TestCase):

    def setUp(self):
        super(TestCreateOrganisation, self).setUp()
        self.STANDARD_VIRKNING1 = {
            "from": "2000-01-01 12:00:00+01",
            "from_included": True,
            "to": "2020-01-01 12:00:00+01",
            "to_included": False
        }
        self.STANDARD_VIRKNING2 = {
            "from": "2020-01-01 12:00:00+01",
            "from_included": True,
            "to": "2030-01-01 12:00:00+01",
            "to_included": False
        }
        self.ORG = {
            "attributter": {
                "organisationegenskaber": [
                    {
                        "brugervendtnoegle": "bvn1",
                        "organisationsnavn": "orgName1",
                        "virkning": self.STANDARD_VIRKNING1
                    }
                ]
            },
            "tilstande": {
                "organisationgyldighed": [
                    {
                        "gyldighed": "Aktiv",
                        "virkning": self.STANDARD_VIRKNING1
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

    def _check_response_400(self):
        self.assertRequestFails(
            '/organisation/organisation',
            400,
            json=self.ORG
        )

    def test_no_note_valid_bvn_no_org_name(self):
        """
        Equivalence classes covered: [2][6][9][13][21][24][29]
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
            '/organisation/organisation',
            self.ORG,
            uuid=r.json['uuid']
        )

    def test_valid_note_valid_org_name_two_org_egenskaber(self):
        """
        Equivalence classes covered: [3][10][15]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation

        self.ORG['note'] = 'This is a note'
        self.ORG['attributter']['organisationegenskaber'].append(
            {
                "brugervendtnoegle": "bvn2",
                "organisationsnavn": "orgName2",
                "virkning": self.STANDARD_VIRKNING2
            }
        )

        r = self._post(self.ORG)

        # Check response

        self._check_response_201(r)

        # Check persisted data

        self.ORG['livscykluskode'] = 'Opstaaet'

        self.assertQueryResponse(
            '/organisation/organisation',
            self.ORG,
            uuid=r.json['uuid'],
            virkningfra='-infinity',
            virkningtil='infinity'
        )

    def test_invalid_note(self):
        """
        Equivalence classes covered: [1]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.ORG['note'] = ['Note cannot be e.g. a list']
        self._check_response_400()

    @unittest.skip(
        'We are allowed to leave out the bvn - this should not be the case')
    def test_bvn_missing(self):
        """
        Equivalence classes covered: [4]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.ORG['attributter']['organisationegenskaber'][0][
            'brugervendtnoegle']
        self._check_response_400()

    @unittest.skip('The REST interface accepts a bvn which is not a string')
    def test_bvn_not_string(self):
        """
        Equivalence classes covered: [5]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.ORG['attributter']['organisationegenskaber'][0][
            'brugervendtnoegle'] = ['BVN cannot be a list']
        self._check_response_400()

    @unittest.skip(
        'The REST interface accepts an organisation name which is not a string')
    def test_org_name_not_string(self):
        """
        Equivalence classes covered: [8]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.ORG['attributter']['organisationegenskaber'][0][
            'organisationnavn'] = ['Organisationnavn cannot be a list']
        self._check_response_400()

    @unittest.skip('When sending a JSON attribute without virkning, '
                   'we do not get a 400 status')
    def test_virkning_missing(self):
        """
        Equivalence classes covered: [11]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.ORG['attributter']['organisationegenskaber'][0]['virkning']
        self._check_response_400()

    def test_org_egenskaber_missing(self):
        """
        Equivalence classes covered: [14]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.ORG['attributter']['organisationegenskaber'].pop()
        self._check_response_400()

    def test_virkning_malformed(self):
        """
        Equivalence classes covered: [12]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.ORG['attributter']['organisationegenskaber'][0]['virkning'] = {
            "from": "xyz",
            "to": "xyz",
        }
        self._check_response_400()

    @unittest.skip('When sending org names that overlap in '
                   'virkning we do not get status 400')
    def test_different_org_names_for_overlapping_virkninger(self):
        """
        Equivalence classes covered: [16]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.ORG['attributter']['organisationegenskaber'].append(
            {
                "brugervendtnoegle": "bvn1",
                "organisationsnavn": "orgName2",
                "virkning": {
                    "from": "2015-01-01 12:00:00+01",
                    "from_included": True,
                    "to": "2030-01-01 12:00:00+01",
                    "to_included": False
                }
            }
        )
        self._check_response_400()

    def test_empty_org_not_allowed(self):
        """
        Equivalence classes covered: [17]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.ORG = {}
        self._check_response_400()

    def test_attributter_missing(self):
        """
        Equivalence classes covered: [18]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.ORG['attributter']
        self._check_response_400()

    def test_two_valid_org_gyldigheder_one_gyldighed_inactive(self):
        """
        Equivalence classes covered: [22][25]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation

        self.ORG['note'] = 'This is a note'
        self.ORG['tilstande']['organisationgyldighed'].append(
            {
                "gyldighed": "Inaktiv",
                "virkning": self.STANDARD_VIRKNING2
            }
        )

        r = self._post(self.ORG)

        # Check response

        self._check_response_201(r)

        # Check persisted data

        self.ORG['livscykluskode'] = 'Opstaaet'

        self.assertQueryResponse(
            '/organisation/organisation',
            self.ORG,
            uuid=r.json['uuid'],
            virkningfra='-infinity',
            virkningtil='infinity'
        )
