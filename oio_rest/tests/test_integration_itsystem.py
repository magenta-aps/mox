# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from tests.test_integration_helper import TestCreateObject


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

        path = "/organisation/itsystem"
        search_params = dict(
            brugervendtnoegle="OIO_REST", itsystemnavn="OIOXML REST API"
        )
        self.parametrized_basic_integration(
            path=path, lora_object=itsystem, search_params=search_params
        )
