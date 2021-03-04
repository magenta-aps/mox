# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0
from typing import Any, Dict

import freezegun

from oio_rest.oio_base import DefaultSearcher, QuickSearcher, configured_db_interface
from tests.util import DBTestCase


@freezegun.freeze_time("2018-01-01")
class TestCreateObject(DBTestCase):
    def setUp(self):
        super(TestCreateObject, self).setUp()
        self.standard_virkning1 = {
            "from": "2000-01-01 12:00:00+01",
            "from_included": True,
            "to": "2020-01-01 12:00:00+01",
            "to_included": False,
        }
        self.standard_virkning2 = {
            "from": "2020-01-01 12:00:00+01",
            "from_included": True,
            "to": "2030-01-01 12:00:00+01",
            "to_included": False,
        }
        self.reference = {
            "uuid": "00000000-0000-0000-0000-000000000000",
            "virkning": self.standard_virkning1,
        }

    def parametrized_basic_integration(
        self, path: str, lora_object: Dict[str, Any], search_params: Dict[str, Any]
    ):
        """
        Tests basic create-search-delete-search flow
        :param path: url-style specification, e.g.: /organisation/bruger
        :param lora_object: a creatable payload consistent of the chosen path
        :param search_params: parameters that allows searching the created object
        :return:
        """

        r = self.perform_request(path, json=lora_object)

        # Check response
        self.assert201(r)

        # Check persisted data
        lora_object["livscykluskode"] = "Opstaaet"
        uuid = r.json()["uuid"]
        self.assertQueryResponse(path, lora_object, uuid=uuid)

        with self.subTest("search"):
            # test searching for objects
            configured_db_interface.searcher = DefaultSearcher()
            self.assertQueryResponse(path, [uuid], uuid=uuid, **search_params)

        with self.subTest("search equivalence"):
            # test equivalence
            configured_db_interface.searcher = QuickSearcher()
            self.assertQueryResponse(path, [uuid], uuid=uuid, **search_params)

        with self.subTest("delete"):
            # test delete
            deleted_uuid = self.delete(f"{path}/{uuid}", json={})
            self.assertEqual(uuid, deleted_uuid)

            with self.subTest("search deleted"):
                # test searching for deleted objects
                configured_db_interface.searcher = DefaultSearcher()
                self.assertQueryResponse(path, [], uuid=uuid, **search_params)

            with self.subTest("search deleted equivalence"):
                # test equivalence
                configured_db_interface.searcher = QuickSearcher()
                self.assertQueryResponse(path, [], uuid=uuid, **search_params)
