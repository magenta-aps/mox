#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

from . import util


class TestCreateItsystem(util.TestCreateObject):
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

        r = self.post('/organisation/itsystem', itsystem)

        # Check response
        self.check_response_201(r)

        # Check persisted data
        itsystem['livscykluskode'] = 'Opstaaet'
        self.assertQueryResponse(
            '/organisation/itsystem',
            itsystem,
            uuid=r.json['uuid']
        )
