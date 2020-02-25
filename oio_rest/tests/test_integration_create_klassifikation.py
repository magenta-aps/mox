# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from tests.test_integration_create_helper import TestCreateObject


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
                        "virkning": self.standard_virkning1
                    }
                ]
            },
            "tilstande": {
                "klassifikationpubliceret": [
                    {
                        "publiceret": "Publiceret",
                        "virkning": self.standard_virkning1
                    }
                ]
            }
        }

        r = self.perform_request('/klassifikation/klassifikation',
                                 json=klassifikation)

        # Check response
        self.assert201(r)

        # Check persisted data
        klassifikation['livscykluskode'] = 'Opstaaet'
        self.assertQueryResponse(
            '/klassifikation/klassifikation',
            klassifikation,
            uuid=r.json['uuid']
        )
