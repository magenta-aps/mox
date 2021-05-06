# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from tests.test_integration_helper import TestCreateObject


class TestCreateTilstand(TestCreateObject):
    def setUp(self):
        super(TestCreateTilstand, self).setUp()

    def test_create_tilstand(self):
        # Create tilstand

        tilstand = {
            "attributter": {
                "tilstandegenskaber": [
                    {
                        "brugervendtnoegle": "bvn",
                        "beskrivelse": "description",
                        "virkning": self.standard_virkning1,
                    }
                ]
            },
            "tilstande": {
                "tilstandstatus": [
                    {"status": "Aktiv", "virkning": self.standard_virkning1}
                ],
                "tilstandpubliceret": [
                    {"publiceret": "Normal", "virkning": self.standard_virkning1}
                ],
            },
            "relationer": {
                "tilstandskvalitet": [
                    {
                        "indeks": 1,
                        "objekttype": "Klasse",
                        "uuid": "f7109356-e87e-4b10-ad5d-36de6e3ee09d",
                        "virkning": self.standard_virkning1,
                    }
                ],
                "tilstandsvaerdi": [
                    {
                        "indeks": 1,
                        "tilstandsvaerdiattr": {
                            "forventet": True,
                            "nominelvaerdi": "82",
                        },
                        "virkning": self.standard_virkning1,
                    }
                ],
            },
        }

        path = "/tilstand/tilstand"
        search_params = dict(brugervendtnoegle="bvn")
        self.parametrized_basic_integration(
            path=path, lora_object=tilstand, search_params=search_params
        )