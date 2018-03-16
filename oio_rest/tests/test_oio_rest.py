import datetime
import json
import types
from unittest import TestCase

import flask
import freezegun
from mock import MagicMock, patch
from werkzeug.exceptions import BadRequest

from oio_rest import oio_rest, db
from oio_rest.custom_exceptions import (BadRequestException, NotFoundException,
                                        GoneException)
from oio_rest.oio_rest import OIOStandardHierarchy, OIORestObject


class TestClassRestObject(OIORestObject):
    pass


class TestClassStandardHierarchy(OIOStandardHierarchy):
    _name = "TestClass"
    _classes = []


class TestOIORestObjectCreateApi(TestCase):
    def setUp(self):
        self.testclass = TestClassRestObject
        self.flask = MagicMock()
        self.flask.add_url_rule = MagicMock()

    def assert_api_rule(self, endpoint, method, function, call_args_list):
        # Check for existence of rule in args list
        rule = next((rule for rule in call_args_list if
                     method in rule[1]['methods'] and
                     endpoint in rule[0] and
                     function in rule[0]), None)
        self.assertIsNotNone(rule, "Expected {} {}".format(method, endpoint))

    def test_create_api_calls_flask_add_url_rule(self):
        self.testclass.create_api(hierarchy="", flask=self.flask,
                                  base_url="URL")
        self.flask.add_url_rule.assert_called()

    def test_create_api_adds_get_objects_rule(self):
        self.testclass.create_api(hierarchy="Hierarchy", flask=self.flask,
                                  base_url="URL")
        self.flask.add_url_rule.assert_called()
        self.assert_api_rule("TestClassRestObject_get_objects", "GET",
                             self.testclass.get_objects,
                             self.flask.add_url_rule.call_args_list)

    def test_create_api_adds_get_object_rule(self):
        self.testclass.create_api(hierarchy="Hierarchy", flask=self.flask,
                                  base_url="URL")
        self.flask.add_url_rule.assert_called()
        self.assert_api_rule("TestClassRestObject_get_object", "GET",
                             self.testclass.get_object,
                             self.flask.add_url_rule.call_args_list)

    def test_create_api_adds_put_object_rule(self):
        self.testclass.create_api(hierarchy="Hierarchy", flask=self.flask,
                                  base_url="URL")
        self.flask.add_url_rule.assert_called()
        self.assert_api_rule("TestClassRestObject_put_object", "PUT",
                             self.testclass.put_object,
                             self.flask.add_url_rule.call_args_list)

    def test_create_api_adds_create_object_rule(self):
        self.testclass.create_api(hierarchy="Hierarchy", flask=self.flask,
                                  base_url="URL")
        self.flask.add_url_rule.assert_called()
        self.assert_api_rule("TestClassRestObject_create_object", "POST",
                             self.testclass.create_object,
                             self.flask.add_url_rule.call_args_list)

    def test_create_api_adds_delete_object_rule(self):
        self.testclass.create_api(hierarchy="Hierarchy", flask=self.flask,
                                  base_url="URL")
        self.flask.add_url_rule.assert_called()
        self.assert_api_rule("TestClassRestObject_delete_object", "DELETE",
                             self.testclass.delete_object,
                             self.flask.add_url_rule.call_args_list)

    def test_create_api_adds_fields_rule(self):
        self.testclass.create_api(hierarchy="Hierarchy", flask=self.flask,
                                  base_url="URL")
        self.flask.add_url_rule.assert_called()
        self.assert_api_rule("TestClassRestObject_fields", "GET",
                             self.testclass.get_fields,
                             self.flask.add_url_rule.call_args_list)


class TestOIORestObject(TestCase):
    def setUp(self):
        self.testclass = TestClassRestObject()
        self.app = flask.Flask(__name__)

    def test_get_args_lowercases_arg_keys(self):
        # Arrange
        params = {
            "KEY1": "Value1",
            "Key2": "VALUE2"
        }

        expected_result = {
            "key1": "Value1",
            "key2": "VALUE2",
        }

        # Act
        with self.app.test_request_context(query_string=params,
                                           method='POST'):
            actual_result = self.testclass._get_args()

        # Assert
        self.assertEqual(expected_result, actual_result)

    def test_get_args_returns_dict_as_default(self):
        # Arrange
        params = {
            "key1": "value1",
            "key2": ["value2", "value3"]
        }

        expected_result = {
            "key1": "value1",
            "key2": "value2"
        }

        # Act
        with self.app.test_request_context(query_string=params,
                                           method='POST'):
            actual_result = self.testclass._get_args()

        # Assert
        self.assertEqual(expected_result, actual_result)

    def test_get_args_returns_as_lists(self):
        # Arrange
        params = {
            "key1": "value1",
            "key2": ["value2", "value3"]
        }

        expected_result = {
            "key1": ["value1"],
            "key2": ["value2", "value3"]
        }

        # Act
        with self.app.test_request_context(query_string=params,
                                           method='POST'):
            actual_result = self.testclass._get_args(True)

        # Assert
        self.assertEqual(expected_result, actual_result)

    def test_get_json_returns_json_if_request_json(self):
        # Arrange
        expected_json = {"testkey": "testvalue"}

        # Act
        with self.app.test_request_context(data=json.dumps(expected_json),
                                           content_type='application/json',
                                           method='POST'):
            actual_json = self.testclass.get_json()

        # Assert
        self.assertEquals(expected_json, actual_json)

    def test_get_json_returns_json_if_form_json(self):
        # Arrange
        expected_json = {"testkey": "testvalue"}

        # Act
        with self.app.test_request_context(
                data='json={}'.format(json.dumps(expected_json)),
                content_type='application/x-www-form-urlencoded',
                method='POST'):
            actual_json = self.testclass.get_json()

        # Assert
        self.assertEquals(expected_json, actual_json)

    def test_get_json_returns_badrequest_if_malformed_form_json(self):
        # Arrange
        # Act
        with self.app.test_request_context(
                data='json={123123123}',
                content_type='application/x-www-form-urlencoded',
                method='POST'), \
             self.assertRaises(BadRequest):
            self.testclass.get_json()

    def test_get_json_returns_none_if_request_json_is_none(self):
        # Arrange
        expected_json = None

        # Act
        with self.app.test_request_context(method='POST'):
            actual_json = self.testclass.get_json()

        # Assert
        self.assertEquals(expected_json, actual_json)

    @patch('oio_rest.oio_rest.db.create_or_import_object')
    def test_create_object_with_input_returns_uuid_and_code_201(self, mock):
        # Arrange
        uuid = "c98d1e8b-0655-40a0-8e86-bb0cc07b0d59"

        expected_data = {"uuid": uuid}

        mock.return_value = uuid

        data = {'note': "NOTE"}

        # Act
        with self.app.test_request_context(data=json.dumps(data),
                                           content_type='application/json',
                                           method='POST'):
            result = self.testclass.create_object()
            actual_data = json.loads(result[0].data)
            actual_code = result[1]

        # Assert
        self.assertDictEqual(expected_data, actual_data)
        self.assertEqual(201, actual_code)

    def test_create_object_with_no_input_returns_uuid_none_and_code_400(
            self):
        # Arrange
        expected_data = {"uuid": None}

        # Act
        with self.app.test_request_context(method='POST'):
            result = self.testclass.create_object()
            actual_data = json.loads(result[0].data)
            actual_code = result[1]

        # Assert
        self.assertDictEqual(expected_data, actual_data)
        self.assertEqual(400, actual_code)

    def test_get_fields(self):
        # Arrange
        expected_fields = ["field1", "field2"]
        db_structure = {"testclassrestobject": expected_fields,
                        "garbage": ["garbage"]}

        with patch("oio_rest.db_structure.REAL_DB_STRUCTURE",
                   new=db_structure):

            # Act
            actual_fields = json.loads(self.testclass.get_fields())

            # Assert
            self.assertEquals(expected_fields, actual_fields)

    @patch('datetime.datetime')
    @patch('oio_rest.oio_rest.db.list_objects')
    def test_get_objects_list_uses_default_params(self,
                                                  mock_list,
                                                  mock_datetime):
        # Arrange
        data = ["1", "2", "3"]

        mock_list.return_value = data

        now = "NOW"
        mock_datetime.now.return_value = now

        expected_args = ('TestClassRestObject', None, now, now, None, None)

        expected_result = {"results": data}

        # Act
        with self.app.test_request_context(method='GET'):
            actual_result_json = self.testclass.get_objects().data
            actual_result = json.loads(actual_result_json)

        # Assert
        actual_args = mock_list.call_args[0]

        self.assertEqual(expected_args, actual_args)
        self.assertDictEqual(expected_result, actual_result)

    @patch('oio_rest.oio_rest.db.list_objects')
    def test_get_objects_list_uses_supplied_params(self, mock):
        # Arrange
        data = ["1", "2", "3"]

        mock.return_value = data

        uuids = ["942f2aae-6151-4894-ac47-842ab93b161b",
                 "18ac08a3-8158-4b68-81aa-adacb1ea0fb3"]
        virkning_fra = "virkning_fra"
        virkning_til = "virkning_til"
        registreret_fra = "registreret_fra"
        registreret_til = "registreret_til"

        expected_args = (
            'TestClassRestObject', uuids, virkning_fra, virkning_til,
            registreret_fra,
            registreret_til)

        expected_result = {"results": data}

        request_params = {
            "uuid": uuids,
            "virkningfra": virkning_fra,
            "virkningtil": virkning_til,
            "registreretfra": registreret_fra,
            "registrerettil": registreret_til,
        }

        # Act
        with self.app.test_request_context(method='GET',
                                           query_string=request_params):
            actual_result_json = self.testclass.get_objects().data
            actual_result = json.loads(actual_result_json)

        # Assert
        actual_args = mock.call_args[0]

        self.assertEqual(expected_args, actual_args)
        self.assertDictEqual(expected_result, actual_result)

    @patch('oio_rest.oio_rest.db.list_objects')
    def test_get_objects_returns_empty_list_on_no_results(self, mock):
        # Arrange

        mock.return_value = None

        # Act
        with self.app.test_request_context(method='GET'):
            actual_result_json = self.testclass.get_objects().data
            actual_result = json.loads(actual_result_json)

        expected_result = {"results": []}

        self.assertDictEqual(expected_result, actual_result)

    @patch('datetime.datetime')
    @patch('oio_rest.oio_rest.build_registration')
    @patch('oio_rest.oio_rest.db.search_objects')
    def test_get_objects_search_uses_default_params(self, mock_search, mock_br,
                                                    mock_datetime):
        # Arrange
        data = ["1", "2", "3"]

        mock_search.return_value = data

        mock_br.return_value = "REGISTRATION"

        now = "NOW"
        mock_datetime.now.return_value = now

        expected_args = (
            'TestClassRestObject', None, "REGISTRATION", now, now,
            None, None, None, None, None, None, None, None, None)

        expected_result = {"results": data}

        request_params = {
            "not_list_arg": "uuid",
        }

        # Act
        with self.app.test_request_context(method='GET',
                                           query_string=request_params):
            actual_result_json = self.testclass.get_objects().data
            actual_result = json.loads(actual_result_json)

        # Assert
        actual_args = mock_search.call_args[0]

        self.assertEqual(expected_args, actual_args)
        self.assertDictEqual(expected_result, actual_result)

    @patch('oio_rest.oio_rest.build_registration')
    @patch('oio_rest.oio_rest.db.search_objects')
    def test_get_objects_search_uses_supplied_params(self, mock_search,
                                                     mock_br):
        # Arrange
        data = ["1", "2", "3"]

        mock_search.return_value = data

        registration = "REGISTRATION"
        mock_br.return_value = registration

        uuid = "17b9a711-5fb4-43aa-8f8d-fe929d23ea68"
        virkning_fra = "virkning_fra"
        virkning_til = "virkning_til"
        registreret_fra = "registreret_fra"
        registreret_til = "registreret_til"
        livscykluskode = "livscykluskode"
        brugerref = "brugerref"
        notetekst = "notetekst"
        vilkaarligattr = ["vilkaarligattr"]
        vilkaarligrel = ["vilkaarligrel"]
        foersteresultat = 100
        maximalantalresultater = 100

        expected_args = (
            'TestClassRestObject', uuid, registration, virkning_fra,
            virkning_til,
            registreret_fra, registreret_til, livscykluskode, brugerref,
            notetekst, vilkaarligattr, vilkaarligrel,
            foersteresultat, maximalantalresultater)

        expected_result = {"results": data}

        request_params = {
            "uuid": uuid,
            "virkningfra": virkning_fra,
            "virkningtil": virkning_til,
            "registreretfra": registreret_fra,
            "registrerettil": registreret_til,
            "livscykluskode": livscykluskode,
            "brugerref": brugerref,
            "notetekst": notetekst,
            "vilkaarligattr": vilkaarligattr,
            "vilkaarligrel": vilkaarligrel,
            "foersteresultat": foersteresultat,
            "maximalantalresultater": maximalantalresultater
        }

        # Act
        with self.app.test_request_context(method='GET',
                                           query_string=request_params):
            actual_result_json = self.testclass.get_objects().data
            actual_result = json.loads(actual_result_json)

        # Assert
        actual_args = mock_search.call_args[0]

        self.assertEqual(expected_args, actual_args)
        self.assertDictEqual(expected_result, actual_result)

    @patch('oio_rest.oio_rest.build_registration')
    @patch('oio_rest.oio_rest.db.search_objects')
    def test_get_objects_search_raises_exception_on_multi_uuid(
            self,
            mock_search,
            mock_br):
        # Arrange
        data = ["1", "2", "3"]

        mock_search.return_value = data

        mock_br.return_value = {}

        uuids = ["94d42aaa-884d-42ba-8ced-964ee34b65c4",
                 "23dd27c8-09dd-4da2-bfe4-b152f97dad59"]

        request_params = {
            "uuid": uuids,
            "brugerref": "99809e77-ede6-48f2-b170-2366bdcd20e5",
        }

        # Act
        with self.app.test_request_context(method='GET',
                                           query_string=request_params), \
             self.assertRaises(BadRequestException):
            self.testclass.get_objects()

    @patch('oio_rest.oio_rest.db.list_objects')
    @freezegun.freeze_time('2017-01-01', tz_offset=1)
    def test_get_object_uses_default_params(self, mock_list):
        # Arrange
        data = [
            {
                "registreringer": [
                    {
                        'livscykluskode': "whatever"
                    }
                ]
            }
        ]
        uuid = "d5995ed0-d527-4841-9e33-112b22aaade1"

        mock_list.return_value = [data]

        now = datetime.datetime.now()

        expected_args = ('TestClassRestObject', [uuid], now, now, None, None)

        expected_result = {uuid: data}

        # Act
        with self.app.test_request_context(method='GET'):
            actual_result_json = self.testclass.get_object(uuid).data
            actual_result = json.loads(actual_result_json)

        # Assert
        actual_args = mock_list.call_args[0]

        self.assertEqual(expected_args, actual_args)
        self.assertEqual(expected_result, actual_result)

    @patch('oio_rest.oio_rest.db.list_objects')
    def test_get_object_uses_supplied_params(self, mock):
        # Arrange
        data = [
            {
                "registreringer": [
                    {
                        'livscykluskode': "whatever"
                    }
                ]
            }
        ]
        uuid = "9a543ba1-c36b-4e47-9f0f-3463ce0e297c"
        virkningfra = datetime.datetime(2012, 1, 1)
        virkningtil = datetime.datetime(2015, 1, 1)
        registreretfra = datetime.datetime(2012, 1, 1)
        registrerettil = datetime.datetime(2015, 1, 1)

        mock.return_value = [data]

        expected_args = (
            'TestClassRestObject', [uuid],
            str(virkningfra),
            str(virkningtil),
            str(registreretfra),
            str(registrerettil))

        expected_result = {uuid: data}

        request_params = {
            "virkningfra": virkningfra,
            "virkningtil": virkningtil,
            "registreretfra": registreretfra,
            "registrerettil": registrerettil,
        }

        # Act
        with self.app.test_request_context(method='GET',
                                           query_string=request_params):
            actual_result_json = self.testclass.get_object(uuid).data
            actual_result = json.loads(actual_result_json)

        # Assert
        actual_args = mock.call_args[0]

        self.assertEqual(expected_args, actual_args)
        self.assertEqual(expected_result, actual_result)

    @patch('oio_rest.oio_rest.db.list_objects')
    def test_get_object_raises_on_no_results(self, mock):
        # Arrange
        data = []
        uuid = "4efbbbde-e197-47be-9d40-e08f1cd00259"

        mock.return_value = data

        # Act
        with self.app.test_request_context(method='GET'), \
             self.assertRaises(NotFoundException):
            self.testclass.get_object(uuid).data

    @patch('oio_rest.oio_rest.db.list_objects')
    def test_get_object_raises_on_deleted_object(self, mock_list):
        # Arrange
        data = [
            {
                "registreringer": [
                    {
                        'livscykluskode': db.Livscyklus.SLETTET.value
                    }
                ]
            }
        ]
        uuid = "d5995ed0-d527-4841-9e33-112b22aaade1"

        mock_list.return_value = [data]

        # Act
        with self.app.test_request_context(method='GET'), \
             self.assertRaises(GoneException):
            self.testclass.get_object(uuid).data

    def test_put_object_with_no_input_returns_uuid_none_and_code_400(
            self):
        # Arrange
        expected_data = {"uuid": None}

        uuid = "092285a1-6dbd-4a22-be47-5dddbbec80e3"

        # Act
        with self.app.test_request_context(method='PUT'):
            result = self.testclass.put_object(uuid)
            actual_data = json.loads(result[0].data)
            actual_code = result[1]

        # Assert
        self.assertDictEqual(expected_data, actual_data)
        self.assertEqual(400, actual_code)

    @patch("oio_rest.oio_rest.db.object_exists")
    @patch("oio_rest.oio_rest.db.create_or_import_object")
    def test_put_object_create_if_not_exists(self, mock_create, mock_exists):
        # type: (MagicMock, MagicMock) -> None
        # Arrange
        uuid = "d321b784-2bbc-40b7-aa1b-c74d931cd535"
        expected_data = {"uuid": uuid}

        mock_exists.return_value = False

        data = {'note': "NOTE"}

        # Act
        with self.app.test_request_context(data=json.dumps(data),
                                           content_type='application/json',
                                           method='PUT'):
            result = self.testclass.put_object(uuid)
            actual_data = json.loads(result[0].data)
            actual_code = result[1]

        # Assert
        mock_create.assert_called()
        self.assertDictEqual(expected_data, actual_data)
        self.assertEqual(200, actual_code)

    @patch("oio_rest.oio_rest.db.get_life_cycle_code")
    @patch("oio_rest.oio_rest.db.object_exists")
    @patch("oio_rest.oio_rest.db.update_object")
    def test_put_object_update_if_deleted_or_passive(self, mock_update,
                                                     mock_exists,
                                                     mock_life_cycle):
        # type: (MagicMock, MagicMock, MagicMock) -> None
        from oio_rest.db import Livscyklus

        # Arrange
        uuid = "fa3c6c47-9594-48e3-918e-cb1208e0144c"
        expected_data = {"uuid": uuid}

        mock_exists.return_value = True

        mock_life_cycle.return_value = Livscyklus.PASSIVERET.value

        data = {'note': "NOTE"}

        # Act
        with self.app.test_request_context(data=json.dumps(data),
                                           content_type='application/json',
                                           method='PUT'):
            result = self.testclass.put_object(uuid)
            actual_data = json.loads(result[0].data)
            actual_code = result[1]

        # Assert
        mock_update.assert_called()
        self.assertDictEqual(expected_data, actual_data)
        self.assertEqual(200, actual_code)

    @patch("oio_rest.oio_rest.db.get_life_cycle_code")
    @patch("oio_rest.oio_rest.db.object_exists")
    @patch("oio_rest.oio_rest.db.update_object")
    def test_put_object_update_if_not_deleted_or_passive(self, mock_update,
                                                         mock_exists,
                                                         mock_life_cycle):
        # type: (MagicMock, MagicMock, MagicMock) -> None
        from oio_rest.db import Livscyklus

        # Arrange
        uuid = "4b4be464-ace2-49d7-9589-04d279b0fe79"
        expected_data = {"uuid": uuid}

        mock_exists.return_value = True
        mock_life_cycle.return_value = Livscyklus.OPSTAAET.value

        data = {'note': "NOTE"}

        # Act
        with self.app.test_request_context(data=json.dumps(data),
                                           content_type='application/json',
                                           method='PUT'):
            result = self.testclass.put_object(uuid)
            actual_data = json.loads(result[0].data)
            actual_code = result[1]

        # Assert
        mock_update.assert_called()
        self.assertDictEqual(expected_data, actual_data)
        self.assertEqual(200, actual_code)

    @patch("oio_rest.oio_rest.db.get_life_cycle_code")
    @patch("oio_rest.oio_rest.db.object_exists")
    @patch("oio_rest.oio_rest.db.passivate_object")
    def test_put_object_passivate_if_livscyklus_passiv(self, mock_passivate,
                                                       mock_exists,
                                                       mock_life_cycle):
        # type: (MagicMock, MagicMock, MagicMock) -> None
        from oio_rest.db import Livscyklus

        # Arrange
        uuid = "b1dfa53f-89a7-4277-8c3d-86703bf87a87"
        expected_data = {"uuid": uuid}

        mock_exists.return_value = True
        mock_life_cycle.return_value = Livscyklus.OPSTAAET.value

        data = {'livscyklus': 'passiv'}

        # Act
        with self.app.test_request_context(data=json.dumps(data),
                                           content_type='application/json',
                                           method='PUT'):
            result = self.testclass.put_object(uuid)
            actual_data = json.loads(result[0].data)
            actual_code = result[1]

        # Assert
        mock_passivate.assert_called()
        self.assertDictEqual(expected_data, actual_data)
        self.assertEqual(200, actual_code)

    @patch("oio_rest.oio_rest.db.delete_object")
    def test_delete_object_returns_expected_result_and_202(self, mock_delete):
        # type: (MagicMock) -> None
        # Arrange
        uuid = "cb94b2ec-33a5-4730-b87e-520e2b82fa9a"
        expected_data = {"uuid": uuid}

        data = {'note': "NOTE"}

        # Act
        with self.app.test_request_context(data=json.dumps(data),
                                           content_type='application/json',
                                           method='PUT'):
            result = self.testclass.delete_object(uuid)
            actual_data = json.loads(result[0].data)
            actual_code = result[1]
        # Assert
        self.assertDictEqual(expected_data, actual_data)
        self.assertEqual(202, actual_code)

    @patch("oio_rest.oio_rest.db.delete_object")
    def test_delete_object_called_with_empty_reg_and_uuid(self, mock_delete):
        # type: (MagicMock) -> None
        # Arrange
        uuid = "cb94b2ec-33a5-4730-b87e-520e2b82fa9a"
        expected_reg = {'attributes': {}, 'relations': None, 'states': {}}

        data = {'note': "NOTE"}

        # Act
        with self.app.test_request_context(data=json.dumps(data),
                                           content_type='application/json',
                                           method='PUT'):
            self.testclass.delete_object(uuid)

        # Assert
        mock_delete.assert_called()
        actual_reg = mock_delete.call_args[0][1]
        actual_uuid = mock_delete.call_args[0][3]
        self.assertEqual(expected_reg, actual_reg)
        self.assertEqual(uuid, actual_uuid)


class TestOIOStandardHierarchy(TestCase):
    def setUp(self):
        self.testclass = TestClassStandardHierarchy()
        self.resetClassFields()

    def resetClassFields(self):
        TestClassStandardHierarchy._classes = []

    def test_setup_api_calls_create_api_on_classes(self):
        # Arrange
        cls1 = MagicMock()
        cls2 = MagicMock()
        TestClassStandardHierarchy._classes = [cls1, cls2]

        # Act
        self.testclass.setup_api(base_url="URL", flask=MagicMock())

        # Assert
        cls1.create_api.assert_called_once()
        cls2.create_api.assert_called_once()

    def test_setup_api_calls_flask_add_url_rule_with_correct_params(self):
        # Arrange
        flask = MagicMock()

        # Act
        self.testclass.setup_api(base_url="URL", flask=flask)

        # Assert
        flask.add_url_rule.assert_called_once()

        ordered_args = flask.add_url_rule.call_args[0]
        keyword_args = flask.add_url_rule.call_args[1]

        self.assertIn('GET', keyword_args['methods'])
        self.assertEquals(u'URL/testclass/classes', ordered_args[0])
        self.assertEquals(u'testclass_classes', ordered_args[1])
        self.assertIsInstance(ordered_args[2], types.FunctionType)

    def test_setup_api_get_classes_returns_correct_result(self):
        # Arrange
        flask = MagicMock()
        flask.add_url_rule = MagicMock()

        cls1 = MagicMock()
        cls1.__name__ = "name1"
        cls2 = MagicMock()
        cls2.__name__ = "name2"
        TestClassStandardHierarchy._classes = [cls1, cls2]

        expected_result = {"name1": "value1", "name2": "value2"}

        db_structure = expected_result.copy()
        db_structure.update({"garbage": "1234"})

        with patch("oio_rest.db_structure.REAL_DB_STRUCTURE",
                   new=db_structure):

            # Act
            self.testclass.setup_api(base_url="URL", flask=flask)

            # Assert
            flask.add_url_rule.assert_called_once()

            get_classes = flask.add_url_rule.call_args[0][2]
            actual_result = json.loads(get_classes())

            self.assertDictEqual(actual_result, expected_result)


class TestOIORest(TestCase):
    def test_typed_get_returns_value(self):
        # Arrange
        expected_result = 'value'
        testkey = 'testkey'
        d = {testkey: expected_result}

        # Act
        actual_result = oio_rest.typed_get(d, testkey, 'default')

        # Assert
        self.assertEqual(expected_result, actual_result)

    def test_typed_get_returns_default_if_value_none(self):
        # Arrange
        expected_result = 'default'
        testkey = 'testkey'
        d = {testkey: None}

        # Act
        actual_result = oio_rest.typed_get(d, testkey, expected_result)

        # Assert
        self.assertEqual(expected_result, actual_result)

    def test_typed_get_raises_on_wrong_type(self):
        # Arrange
        default = 1234

        testkey = 'testkey'
        d = {testkey: "value"}

        # Act & Assert
        with self.assertRaises(BadRequestException):
            oio_rest.typed_get(d, testkey, default)
