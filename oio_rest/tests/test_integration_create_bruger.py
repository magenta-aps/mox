# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from tests.test_integration_create_helper import TestCreateObject


class TestCreateBruger(TestCreateObject):
    def setUp(self):
        super(TestCreateBruger, self).setUp()

    def test_create_bruger(self):
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

        r = self.perform_request("/organisation/bruger", json=facet)

        # Check response
        self.assert201(r)

        # Check persisted data
        facet["livscykluskode"] = "Opstaaet"
        self.assertQueryResponse("/organisation/bruger", facet, uuid=r.json["uuid"])
