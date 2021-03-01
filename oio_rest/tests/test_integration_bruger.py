# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0
from oio_rest.oio_base import DefaultSearcher, QuickSearcher, configured_db_interface
from tests.test_integration_create_helper import TestCreateObject


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

        r = self.perform_request("/organisation/bruger", json=facet)

        # Check response
        self.assert201(r)

        # Check persisted data
        facet["livscykluskode"] = "Opstaaet"
        uuid = r.json["uuid"]
        self.assertQueryResponse("/organisation/bruger", facet, uuid=uuid)

        with self.subTest("search"):
            # test searching for objects
            configured_db_interface.searcher = DefaultSearcher()
            self.assertQueryResponse(
                "/organisation/bruger", [uuid], uuid=uuid, brugervendtnoegle="bvn"
            )

        with self.subTest("search equivalence"):
            # test equivalence
            configured_db_interface.searcher = QuickSearcher()
            self.assertQueryResponse(
                "/organisation/bruger", [uuid], uuid=uuid, brugervendtnoegle="bvn"
            )

        with self.subTest("delete"):
            # test delete
            deleted_uuid = self.delete(f"/organisation/bruger/{uuid}", json={})
            self.assertEqual(uuid, deleted_uuid)

            with self.subTest("search deleted"):
                # test searching for deleted objects
                configured_db_interface.searcher = DefaultSearcher()
                self.assertQueryResponse(
                    "/organisation/bruger", [], uuid=uuid, brugervendtnoegle="bvn"
                )

            with self.subTest("search deleted equivalence"):
                # test equivalence
                configured_db_interface.searcher = QuickSearcher()
                self.assertQueryResponse(
                    "/organisation/bruger", [], uuid=uuid, brugervendtnoegle="bvn"
                )
