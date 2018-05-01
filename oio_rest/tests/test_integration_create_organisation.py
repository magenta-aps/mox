#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

import copy
import json
import re
import unittest

from . import util

UUID_REGEX = re.compile('[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-'
                        '[a-fA-F0-9]{4}-[a-fA-F0-9]{12}')


class TestCreateOrganisation(util.TestCase):

    def setUp(self):
        super(TestCreateOrganisation, self).setUp()
        self.standard_virkning1 = {
            "from": "2000-01-01 12:00:00+01",
            "from_included": True,
            "to": "2020-01-01 12:00:00+01",
            "to_included": False
        }
        self.standard_virkning2 = {
            "from": "2020-01-01 12:00:00+01",
            "from_included": True,
            "to": "2030-01-01 12:00:00+01",
            "to_included": False
        }
        self.reference = {
            'uuid': '00000000-0000-0000-0000-000000000000',
            'virkning': self.standard_virkning1
        }
        self.org = {
            "attributter": {
                "organisationegenskaber": [
                    {
                        "brugervendtnoegle": "bvn1",
                        "organisationsnavn": "orgName1",
                        "virkning": self.standard_virkning1
                    }
                ]
            },
            "tilstande": {
                "organisationgyldighed": [
                    {
                        "gyldighed": "Aktiv",
                        "virkning": self.standard_virkning1
                    }
                ]
            },
        }

    def _post(self, payload, url='/organisation/organisation'):
        """
        Make HTTP POST request to /organisation/organisation
        :param payload: dictionary containing payload to LoRa
        :return: Response from LoRa
        """
        r = self.client.post(
            url,
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
            json=self.org
        )

    def test_no_note_valid_bvn_no_org_name_no_relations(self):
        """
        Equivalence classes covered: [2][6][9][13][21][24][29][38]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation
        del self.org['attributter']['organisationegenskaber'][0][
            'organisationsnavn']

        r = self._post(self.org)

        # Check response
        self._check_response_201(r)

        # Check persisted data
        self.org['livscykluskode'] = 'Opstaaet'
        self.assertQueryResponse(
            '/organisation/organisation',
            self.org,
            uuid=r.json['uuid']
        )

    def test_valid_note_valid_org_name_two_org_egenskaber(self):
        """
        Equivalence classes covered: [3][10][15]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation
        self.org['note'] = 'This is a note'
        self.org['attributter']['organisationegenskaber'].append(
            {
                "brugervendtnoegle": "bvn2",
                "organisationsnavn": "orgName2",
                "virkning": self.standard_virkning2
            }
        )
        r = self._post(self.org)

        # Check response
        self._check_response_201(r)

        # Check persisted data
        self.org['livscykluskode'] = 'Opstaaet'
        self.assertQueryResponse(
            '/organisation/organisation',
            self.org,
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

        self.org['note'] = ['Note cannot be e.g. a list']
        self._check_response_400()

    @unittest.skip(
        'We are allowed to leave out the bvn - this should not be the case')
    def test_bvn_missing(self):
        """
        Equivalence classes covered: [4]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.org['attributter']['organisationegenskaber'][0][
            'brugervendtnoegle']
        self._check_response_400()

    @unittest.skip('The REST interface accepts a bvn which is not a string')
    def test_bvn_not_string(self):
        """
        Equivalence classes covered: [5]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org['attributter']['organisationegenskaber'][0][
            'brugervendtnoegle'] = ['BVN cannot be a list']
        self._check_response_400()

    @unittest.skip(
        'The REST interface accepts an organisation name which is not a string'
    )
    def test_org_name_not_string(self):
        """
        Equivalence classes covered: [8]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org['attributter']['organisationegenskaber'][0][
            'organisationnavn'] = ['Organisationnavn cannot be a list']
        self._check_response_400()

    @unittest.skip('When sending a JSON attribute without virkning, '
                   'we do not get a 400 status')
    def test_virkning_missing_attributter(self):
        """
        Equivalence classes covered: [11]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.org['attributter']['organisationegenskaber'][0]['virkning']
        self._check_response_400()

    def test_org_egenskaber_missing(self):
        """
        Equivalence classes covered: [14]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org['attributter']['organisationegenskaber'].pop()
        self._check_response_400()

    def test_virkning_malformed_attributter(self):
        """
        Equivalence classes covered: [12]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org['attributter']['organisationegenskaber'][0]['virkning'] = {
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

        self.org['attributter']['organisationegenskaber'].append(
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

        self.org = {}
        self._check_response_400()

    def test_attributter_missing(self):
        """
        Equivalence classes covered: [18]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.org['attributter']
        self._check_response_400()

    @unittest.skip('Setting "attributter" several times in the request '
                   'JSON does not result in status code 400')
    def test_attributter_key_not_allowed_twice(self):
        """
        Equivalence classes covered: [40]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        org = json.dumps(self.org)[:-1] + ',"attributter":' + json.dumps(
            self.org['attributter']) + '}'
        self.org = json.loads(org)

        self._check_response_400()

    def test_two_valid_org_gyldigheder_one_gyldighed_inactive(self):
        """
        Equivalence classes covered: [22][25]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation
        self.org['note'] = 'This is a note'
        self.org['tilstande']['organisationgyldighed'].append(
            {
                "gyldighed": "Inaktiv",
                "virkning": self.standard_virkning2
            }
        )
        r = self._post(self.org)

        # Check response
        self._check_response_201(r)

        # Check persisted data
        self.org['livscykluskode'] = 'Opstaaet'
        self.assertQueryResponse(
            '/organisation/organisation',
            self.org,
            uuid=r.json['uuid'],
            virkningfra='-infinity',
            virkningtil='infinity'
        )

    def test_tilstande_missing(self):
        """
        Equivalence classes covered: [19]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.org['tilstande']
        self._check_response_400()

    @unittest.skip('Setting "tilstande" several times in the request '
                   'JSON does not result in status code 400')
    def test_tilstande_key_not_allowed_twice(self):
        """
        Equivalence classes covered: [41]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        org = json.dumps(self.org)[:-1] + ',"tilstande":' + json.dumps(
            self.org['tilstande']) + '}'
        self.org = json.loads(org)

        self._check_response_400()

    def test_org_gyldighed_missing(self):
        """
        Equivalence classes covered: [20]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org['tilstande']['organisationgyldighed'].pop()
        self._check_response_400()

    def test_gyldighed_invalid(self):
        """
        Equivalence classes covered: [23]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org['tilstande']['organisationgyldighed'][0][
            'gyldighed'] = 'invalid'
        self._check_response_400()

    @unittest.skip('When sending a JSON tilstand without gyldighed, '
                   'we do not get a 400 status')
    def test_gyldighed_missing(self):
        """
        Equivalence classes covered: [26]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.org['tilstande']['organisationgyldighed'][0]['gyldighed']
        self._check_response_400()

    @unittest.skip('When sending a JSON attribute without virkning, '
                   'we do not get a 400 status')
    def test_virkning_missing_tilstande(self):
        """
        Equivalence classes covered: [27]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.org['tilstande']['organisationgyldighed'][0]['virkning']
        self._check_response_400()

    def test_virkning_malformed_tilstande(self):
        """
        Equivalence classes covered: [28]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org['tilstande']['organisationgyldighed'][0]['virkning'] = {
            "from": "xyz",
            "to": "xyz",
        }
        self._check_response_400()

    @unittest.skip('When sending gyldigheder that overlap in '
                   'virkning we do not get status 400')
    def test_different_gyldigheder_for_overlapping_virkninger(self):
        """
        Equivalence classes covered: [30]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org['tilstande']['organisationgyldighed'].append(
            {
                "gyldighed": "Inaktiv",
                "virkning": {
                    "from": "2015-01-01 12:00:00+01",
                    "from_included": True,
                    "to": "2030-01-01 12:00:00+01",
                    "to_included": False
                }
            }
        )
        self._check_response_400()

    def test_empty_list_of_relations(self):
        """
        Equivalence classes covered: [31]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation
        self.org['relationer'] = {}
        r = self._post(self.org)

        # Check response
        self._check_response_201(r)

        # Check persisted data
        self.org['livscykluskode'] = 'Opstaaet'
        del self.org['relationer']
        self.assertQueryResponse(
            '/organisation/organisation',
            self.org,
            uuid=r.json['uuid']
        )

    def test_specific_relation_list_empty(self):
        """
        Equivalence classes covered: [42]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation
        self.org['relationer'] = {
            'overordnet': []
        }
        r = self._post(self.org)

        # Check response
        self._check_response_201(r)

        # Check persisted data
        self.org['livscykluskode'] = 'Opstaaet'
        del self.org['relationer']
        self.assertQueryResponse(
            '/organisation/organisation',
            self.org,
            uuid=r.json['uuid']
        )

    def test_one_uuid_per_relation_reference_all_relation_names_tested(self):
        """
        Equivalence classes covered: [32][35][37]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create dummy "klasse"
        klasse = {
            "attributter": {
                "klasseegenskaber": [
                    {
                        "brugervendtnoegle": "klasse1",
                        "titel": "dummy_klasse",
                        "virkning": self.standard_virkning1
                    }
                ]
            },
            "tilstande": {
                "klassepubliceret": [
                    {
                        "publiceret": "Publiceret",
                        "virkning": self.standard_virkning1
                    }
                ]
            }
        }
        r = self._post(klasse, '/klassifikation/klasse')
        self._check_response_201(r)

        relationtype = copy.copy(self.reference)
        relationtype['uuid'] = r.json['uuid']

        # Create organisation
        self.org['relationer'] = {
            'adresser': [self.reference],
            'ansatte': [self.reference],
            'branche': [self.reference],
            'myndighed': [self.reference],
            'myndighedstype': [relationtype],
            'opgaver': [self.reference],
            'overordnet': [self.reference],
            'produktionsenhed': [self.reference],
            'skatteenhed': [self.reference],
            'tilhoerer': [self.reference],
            'tilknyttedebrugere': [self.reference],
            'tilknyttedeenheder': [self.reference],
            'tilknyttedefunktioner': [self.reference],
            'tilknyttedeinteressefaellesskaber': [self.reference],
            'tilknyttedeorganisationer': [self.reference],
            'tilknyttedepersoner': [self.reference],
            'tilknyttedeitsystemer': [self.reference],
            'virksomhed': [self.reference],
            'virksomhedstype': [relationtype]
        }
        r = self._post(self.org)

        # Check response
        self._check_response_201(r)

        # Check persisted data
        self.org['livscykluskode'] = 'Opstaaet'
        self.assertQueryResponse(
            '/organisation/organisation',
            self.org,
            uuid=r.json['uuid']
        )

    def test_adding_two_relations(self):
        """
        Equivalence classes covered: [33]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details.

        We assume that is it work for all relations if it is working for
        e.g. addresses.
        """

        # Create organisation
        self.org['relationer'] = {
            'adresser': [
                self.reference,
                {
                    'uuid': '10000000-0000-0000-0000-000000000000',
                    'virkning': self.standard_virkning1
                }
            ]
        }
        r = self._post(self.org)

        # Check response
        self._check_response_201(r)

        # Check persisted data
        self.org['livscykluskode'] = 'Opstaaet'
        self.assertQueryResponse(
            '/organisation/organisation',
            self.org,
            uuid=r.json['uuid']
        )

    def test_reference_in_relation_must_be_an_uuid(self):
        """
        Equivalence classes covered: [34]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org['relationer'] = {
            'adresser': [
                {
                    'uuid': 'not an UUID',
                    'virkning': self.standard_virkning1
                }
            ]
        }
        self._check_response_400()

    def test_invalid_relation_name_not_allowed(self):
        """
        Equivalence classes covered: [36]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org['relationer'] = {
            'unknown': [self.reference]
        }
        self._check_response_400()

    @unittest.skip('Setting "relationer" several times in the request '
                   'JSON does not result in status code 400')
    def test_relationer_key_not_allowed_twice(self):
        """
        Equivalence classes covered: [39]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org['relationer'] = {
            'adresser': [self.reference]
        }
        org = json.dumps(self.org)[:-1] + ',"relationer":' + json.dumps(
            self.org['relationer']) + '}'
        self.org = json.loads(org)

        self._check_response_400()
