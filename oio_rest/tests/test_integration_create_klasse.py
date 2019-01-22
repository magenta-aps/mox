#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

from tests.test_integration_create_helper import TestCreateObject


class TestCreateKlasse(TestCreateObject):
    def setUp(self):
        super(TestCreateKlasse, self).setUp()

    def test_create_klasse(self):
        klasse = {
            "attributter": {
                "klasseegenskaber": [
                    {
                        "brugervendtnoegle": "bvn",
                        "titel": "stor titel",
                        "integrationsdata": "data fra andet system",
                        "virkning": self.standard_virkning1
                    }
                ]
            },
            "tilstande": {
                "klassepubliceret": [
                    {
                        "publiceret": "Publiceret",
                        "virkning": self.standard_virkning1
                    }
                ]
            }
        }

        r = self.perform_request('/klassifikation/klasse', json=klasse)

        # Check response
        self.assert201(r)

        # Check persisted data
        klasse['livscykluskode'] = 'Opstaaet'
        self.assertQueryResponse(
            '/klassifikation/klasse',
            klasse,
            uuid=r.json['uuid']
        )
