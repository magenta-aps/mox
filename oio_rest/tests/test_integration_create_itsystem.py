#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

from tests.test_integration_create_helper import TestCreateObject


class TestCreateItsystem(TestCreateObject):
    def setUp(self):
        super(TestCreateItsystem, self).setUp()

    def test_create_itsystem(self):
        # Create itsystem

        itsystem = {
            "note": "Nyt IT-system",
            "attributter": {
                "itsystemegenskaber": [
                    {
                        "brugervendtnoegle": "OIO_REST",
                        "itsystemnavn": "OIOXML REST API",
                        "itsystemtype": "Kommunalt system",
                        "konfigurationreference": ["Ja", "Nej", "Ved ikke"],
                        "virkning": self.standard_virkning1
                    }
                ]
            },
            "tilstande": {
                "itsystemgyldighed": [
                    {
                        "gyldighed": "Aktiv",
                        "virkning": self.standard_virkning1
                    }
                ]
            },
        }

        r = self.perform_request('/organisation/itsystem', json=itsystem)

        # Check response
        self.assert201(r)

        # Check persisted data
        itsystem['livscykluskode'] = 'Opstaaet'
        self.assertQueryResponse(
            '/organisation/itsystem',
            itsystem,
            uuid=r.json['uuid']
        )
