# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

import copy
import json
import unittest

from tests.test_integration_helper import TestCreateObject


class TestCreateOrganisation(TestCreateObject):
    def setUp(self):
        super(TestCreateOrganisation, self).setUp()
        self.org = {
            "attributter": {
                "organisationegenskaber": [
                    {
                        "brugervendtnoegle": "bvn1",
                        "organisationsnavn": "orgName1",
                        "virkning": self.standard_virkning1,
                    }
                ]
            },
            "tilstande": {
                "organisationgyldighed": [
                    {"gyldighed": "Aktiv", "virkning": self.standard_virkning1}
                ]
            },
        }
        self.URL = "/organisation/organisation"

    def test_no_note_valid_bvn_no_org_name_no_relations(self):
        """
        Equivalence classes covered: [2][6][9][13][21][24][29][38]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation
        del self.org["attributter"]["organisationegenskaber"][0]["organisationsnavn"]

        r = self.perform_request(self.URL, json=self.org)

        # Check response
        self.assert201(r)

        # Check persisted data
        self.org["livscykluskode"] = "Opstaaet"
        self.assertQueryResponse(
            "/organisation/organisation", self.org, uuid=r.json["uuid"]
        )

    def test_valid_note_valid_org_name_two_org_egenskaber(self):
        """
        Equivalence classes covered: [3][10][15]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation
        self.org["note"] = "This is a note"
        self.org["attributter"]["organisationegenskaber"].append(
            {
                "brugervendtnoegle": "bvn2",
                "organisationsnavn": "orgName2",
                "virkning": self.standard_virkning2,
            }
        )
        r = self.perform_request(self.URL, json=self.org)

        # Check response
        self.assert201(r)

        # Check persisted data
        self.org["livscykluskode"] = "Opstaaet"
        self.assertQueryResponse(
            "/organisation/organisation",
            self.org,
            uuid=r.json["uuid"],
            virkningfra="-infinity",
            virkningtil="infinity",
        )

    def test_invalid_note(self):
        """
        Equivalence classes covered: [1]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org["note"] = ["Note cannot be e.g. a list"]
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_bvn_missing(self):
        """
        Equivalence classes covered: [4]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.org["attributter"]["organisationegenskaber"][0]["brugervendtnoegle"]
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_bvn_not_string(self):
        """
        Equivalence classes covered: [5]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org["attributter"]["organisationegenskaber"][0]["brugervendtnoegle"] = [
            "BVN cannot be a list"
        ]
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_org_name_not_string(self):
        """
        Equivalence classes covered: [8]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org["attributter"]["organisationegenskaber"][0]["organisationnavn"] = [
            "Organisationnavn cannot be a list"
        ]
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_virkning_missing_attributter(self):
        """
        Equivalence classes covered: [11]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.org["attributter"]["organisationegenskaber"][0]["virkning"]
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_org_egenskaber_missing(self):
        """
        Equivalence classes covered: [14]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org["attributter"]["organisationegenskaber"].pop()
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_virkning_malformed_attributter(self):
        """
        Equivalence classes covered: [12]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org["attributter"]["organisationegenskaber"][0]["virkning"] = {
            "from": "xyz",
            "to": "xyz",
        }
        self.assertRequestFails(self.URL, 400, json=self.org)

    @unittest.expectedFailure
    def test_different_org_names_for_overlapping_virkninger(self):
        """Sending org names that overlap in virkning should fail

        Equivalence classes covered: [16]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org["attributter"]["organisationegenskaber"].append(
            {
                "brugervendtnoegle": "bvn1",
                "organisationsnavn": "orgName2",
                "virkning": {
                    "from": "2015-01-01 12:00:00+01",
                    "from_included": True,
                    "to": "2030-01-01 12:00:00+01",
                    "to_included": False,
                },
            }
        )
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_empty_org_not_allowed(self):
        """
        Equivalence classes covered: [17]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org = {}
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_attributter_missing(self):
        """
        Equivalence classes covered: [18]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.org["attributter"]
        self.assertRequestFails(self.URL, 400, json=self.org)

    @unittest.expectedFailure
    def test_attributter_key_not_allowed_twice(self):
        """Setting "attributter" several times in the request JSON should fail

        Equivalence classes covered: [40]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        org = (
            json.dumps(self.org)[:-1]
            + ',"attributter":'
            + json.dumps(self.org["attributter"])
            + "}"
        )
        self.org = json.loads(org)

        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_two_valid_org_gyldigheder_one_gyldighed_inactive(self):
        """
        Equivalence classes covered: [22][25]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation
        self.org["note"] = "This is a note"
        self.org["tilstande"]["organisationgyldighed"].append(
            {"gyldighed": "Inaktiv", "virkning": self.standard_virkning2}
        )
        r = self.perform_request(self.URL, json=self.org)

        # Check response
        self.assert201(r)

        # Check persisted data
        self.org["livscykluskode"] = "Opstaaet"
        self.assertQueryResponse(
            "/organisation/organisation",
            self.org,
            uuid=r.json["uuid"],
            virkningfra="-infinity",
            virkningtil="infinity",
        )

    def test_tilstande_missing(self):
        """
        Equivalence classes covered: [19]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.org["tilstande"]
        self.assertRequestFails(self.URL, 400, json=self.org)

    @unittest.expectedFailure
    def test_tilstande_key_not_allowed_twice(self):
        """Setting "tilstande" several times in the request should fail

        Equivalence classes covered: [41]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        org = (
            json.dumps(self.org)[:-1]
            + ',"tilstande":'
            + json.dumps(self.org["tilstande"])
            + "}"
        )
        self.org = json.loads(org)

        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_org_gyldighed_missing(self):
        """
        Equivalence classes covered: [20]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org["tilstande"]["organisationgyldighed"].pop()
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_gyldighed_invalid(self):
        """
        Equivalence classes covered: [23]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org["tilstande"]["organisationgyldighed"][0]["gyldighed"] = "invalid"
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_gyldighed_missing(self):
        """
        Equivalence classes covered: [26]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.org["tilstande"]["organisationgyldighed"][0]["gyldighed"]
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_virkning_missing_tilstande(self):
        """
        Equivalence classes covered: [27]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        del self.org["tilstande"]["organisationgyldighed"][0]["virkning"]
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_virkning_malformed_tilstande(self):
        """
        Equivalence classes covered: [28]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org["tilstande"]["organisationgyldighed"][0]["virkning"] = {
            "from": "xyz",
            "to": "xyz",
        }
        self.assertRequestFails(self.URL, 400, json=self.org)

    @unittest.expectedFailure
    def test_different_gyldigheder_for_overlapping_virkninger(self):
        """Sending gyldigheder that overlap in virkning should fail

        Equivalence classes covered: [30]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org["tilstande"]["organisationgyldighed"].append(
            {
                "gyldighed": "Inaktiv",
                "virkning": {
                    "from": "2015-01-01 12:00:00+01",
                    "from_included": True,
                    "to": "2030-01-01 12:00:00+01",
                    "to_included": False,
                },
            }
        )
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_empty_list_of_relations(self):
        """
        Equivalence classes covered: [31]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation
        self.org["relationer"] = {}
        r = self.perform_request(self.URL, json=self.org)

        # Check response
        self.assert201(r)

        # Check persisted data
        self.org["livscykluskode"] = "Opstaaet"
        del self.org["relationer"]
        self.assertQueryResponse(
            "/organisation/organisation", self.org, uuid=r.json["uuid"]
        )

    def test_specific_relation_list_empty(self):
        """
        Equivalence classes covered: [42]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        # Create organisation
        self.org["relationer"] = {"overordnet": []}
        r = self.perform_request(self.URL, json=self.org)

        # Check response
        self.assert201(r)

        # Check persisted data
        self.org["livscykluskode"] = "Opstaaet"
        del self.org["relationer"]
        self.assertQueryResponse(
            "/organisation/organisation", self.org, uuid=r.json["uuid"]
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
                        "virkning": self.standard_virkning1,
                    }
                ]
            },
            "tilstande": {
                "klassepubliceret": [
                    {"publiceret": "Publiceret", "virkning": self.standard_virkning1}
                ]
            },
        }
        r = self.perform_request("/klassifikation/klasse", json=klasse)
        self.assert201(r)

        relationtype = copy.copy(self.reference)
        relationtype["uuid"] = r.json["uuid"]

        # Create organisation
        self.org["relationer"] = {
            "adresser": [self.reference],
            "ansatte": [self.reference],
            "branche": [self.reference],
            "myndighed": [self.reference],
            "myndighedstype": [relationtype],
            "opgaver": [self.reference],
            "overordnet": [self.reference],
            "produktionsenhed": [self.reference],
            "skatteenhed": [self.reference],
            "tilhoerer": [self.reference],
            "tilknyttedebrugere": [self.reference],
            "tilknyttedeenheder": [self.reference],
            "tilknyttedefunktioner": [self.reference],
            "tilknyttedeinteressefaellesskaber": [self.reference],
            "tilknyttedeorganisationer": [self.reference],
            "tilknyttedepersoner": [self.reference],
            "tilknyttedeitsystemer": [self.reference],
            "virksomhed": [self.reference],
            "virksomhedstype": [relationtype],
        }
        r = self.perform_request(self.URL, json=self.org)

        # Check response
        self.assert201(r)

        # Check persisted data
        self.org["livscykluskode"] = "Opstaaet"
        self.assertQueryResponse(
            "/organisation/organisation", self.org, uuid=r.json["uuid"]
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
        self.org["relationer"] = {
            "adresser": [
                self.reference,
                {
                    "uuid": "10000000-0000-0000-0000-000000000000",
                    "virkning": self.standard_virkning1,
                },
            ]
        }
        r = self.perform_request(self.URL, json=self.org)

        # Check response
        self.assert201(r)

        # Check persisted data
        self.org["livscykluskode"] = "Opstaaet"
        self.assertQueryResponse(
            "/organisation/organisation", self.org, uuid=r.json["uuid"]
        )

    def test_reference_in_relation_must_be_an_uuid(self):
        """
        Equivalence classes covered: [34]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org["relationer"] = {
            "adresser": [{"uuid": "not an UUID", "virkning": self.standard_virkning1}]
        }
        self.assertRequestFails(self.URL, 400, json=self.org)

    def test_invalid_relation_name_not_allowed(self):
        """
        Equivalence classes covered: [36]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org["relationer"] = {"unknown": [self.reference]}
        self.assertRequestFails(self.URL, 400, json=self.org)

    @unittest.expectedFailure
    def test_relationer_key_not_allowed_twice(self):
        """Setting "relationer" several times in the request JSON should fail

        Equivalence classes covered: [39]
        See https://github.com/magenta-aps/mox/doc/Systematic_testing.rst for
        further details
        """

        self.org["relationer"] = {"adresser": [self.reference]}
        org = (
            json.dumps(self.org)[:-1]
            + ',"relationer":'
            + json.dumps(self.org["relationer"])
            + "}"
        )
        self.org = json.loads(org)

        self.assertRequestFails(self.URL, 400, json=self.org)
