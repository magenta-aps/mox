# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

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
                        "virkning": self.standard_virkning1,
                    }
                ]
            },
            "tilstande": {
                "itsystemgyldighed": [
                    {"gyldighed": "Aktiv", "virkning": self.standard_virkning1}
                ]
            },
        }

        r = self.perform_request("/organisation/itsystem", json=itsystem)

        # Check response
        self.assert201(r)

        # Check persisted data
        itsystem["livscykluskode"] = "Opstaaet"
        self.assertQueryResponse(
            "/organisation/itsystem", itsystem, uuid=r.json["uuid"]
        )
