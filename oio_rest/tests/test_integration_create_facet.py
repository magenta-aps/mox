# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from tests.test_integration_create_helper import TestCreateObject


class TestCreateFacet(TestCreateObject):
    def setUp(self):
        super(TestCreateFacet, self).setUp()

    def test_create_facet(self):
        facet = {
            "attributter": {
                "facetegenskaber": [
                    {
                        "brugervendtnoegle": "bvn",
                        "integrationsdata": "data fra andet system",
                        "virkning": self.standard_virkning1,
                    }
                ]
            },
            "tilstande": {
                "facetpubliceret": [
                    {"publiceret": "Publiceret", "virkning": self.standard_virkning1}
                ]
            },
        }

        r = self.perform_request("/klassifikation/facet", json=facet)

        # Check response
        self.assert201(r)

        # Check persisted data
        facet["livscykluskode"] = "Opstaaet"
        self.assertQueryResponse("/klassifikation/facet", facet, uuid=r.json["uuid"])
