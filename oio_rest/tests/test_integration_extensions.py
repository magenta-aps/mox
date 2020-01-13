# SPDX-FileCopyrightText: 2019-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from . import util
from tests.util import ExtDBTestCase


class TestBooleanAttribute(ExtDBTestCase):
    db_structure_extensions = {
        "facet": {
            "attributter": {
                "udvidelser": [
                    "primær"
                ]
            },
            "attributter_metadata": {
                "udvidelser": {
                    "primær": {
                        "type": "boolean"
                    }
                }
            }
        }
    }

    def test_create_and_search(self):
        payload = util.get_fixture('facet_opret.json')

        # this one lacks our extended attribute
        missing = self.post('/klassifikation/facet', payload)

        virkning = payload['attributter']['facetegenskaber'][0]['virkning']

        payload['attributter']['facetudvidelser'] = [{
            'virkning': virkning,
        }]

        unspecified = self.post('/klassifikation/facet', payload)

        payload['attributter']['facetudvidelser'][0]['primær'] = True

        primary = self.post('/klassifikation/facet', payload)

        payload['attributter']['facetudvidelser'][0]['primær'] = False

        secondary = self.post('/klassifikation/facet', payload)

        self.assertQueryResponse(
            '/klassifikation/facet',
            [primary, secondary, unspecified, missing],
            bvn='%')

        self.assertQueryResponse(
            '/klassifikation/facet', [secondary], primær='0')

        self.assertQueryResponse(
            '/klassifikation/facet', [primary], primær='1')

    def test_invalid_value(self):
        # not what we want, since it triggers an error 500, but...
        with self.assertRaises(ValueError):
            self.assertRequestResponse(
                '/klassifikation/facet?primær=42',
                {},
                status_code=400,
            )
