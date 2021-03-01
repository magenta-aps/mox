# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from tests.test_integration_helper import TestCreateObject


class TestCreateKlassifikation(TestCreateObject):
    def setUp(self):
        super(TestCreateKlassifikation, self).setUp()

    def test_create_klassifikation(self):
        klassifikation = {
            "attributter": {
                "klassifikationegenskaber": [
                    {
                        "brugervendtnoegle": "bvn",
                        "integrationsdata": "data fra andet system",
                        "virkning": self.standard_virkning1,
                    }
                ]
            },
            "tilstande": {
                "klassifikationpubliceret": [
                    {"publiceret": "Publiceret", "virkning": self.standard_virkning1}
                ]
            },
        }

        path = "/klassifikation/klassifikation"
        search_params = dict(brugervendtnoegle="bvn")
        self.parametrized_basic_integration(
            path=path, lora_object=klassifikation, search_params=search_params
        )
