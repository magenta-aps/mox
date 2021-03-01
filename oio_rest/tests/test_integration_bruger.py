# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0
from tests.test_integration_helper import TestCreateObject


class TestCreateBruger(TestCreateObject):
    def setUp(self):
        super(TestCreateBruger, self).setUp()

    def test_bruger(self):

        # test create
        facet = {
            "attributter": {
                "brugeregenskaber": [
                    {
                        "brugervendtnoegle": "bvn",
                        "integrationsdata": "data fra andet system",
                        "virkning": self.standard_virkning1,
                    }
                ]
            },
            "tilstande": {
                "brugergyldighed": [
                    {"gyldighed": "Aktiv", "virkning": self.standard_virkning1}
                ]
            },
        }

        path = "/organisation/bruger"
        search_params = dict(brugervendtnoegle="bvn")

        self.parametrized_basic_integration(
            path=path, lora_object=facet, search_params=search_params
        )
