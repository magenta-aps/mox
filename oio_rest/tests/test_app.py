# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


from unittest import TestCase

from mock import patch

from oio_rest import app as flaskapp


class TestApp(TestCase):
    def setUp(self):
        flaskapp.testing = True
        self.app = flaskapp.test_client()

    def test_route_get_json_schema_returns_404_on_missing_obj(self):
        result = self.app.get('/get-json-schema')
        self.assertEqual(404, result.status_code)

    def test_route_get_token_post_returns_400_on_missing_user_and_pass(self):
        # Arrange

        # Act
        result = self.app.post('/get-token')

        # Assert
        self.assertEqual(400, result.status_code)

    @patch('oio_rest.views.tokens.get_token')
    def test_route_get_token_post_returns_403_on_auth_failed(self,
                                                             mock_get_token):
        # Arrange
        mock_get_token.side_effect = Exception

        # Act
        result = self.app.post('/get-token',
                               data={'username': 'user', 'password': 'pass'})

        # Assert
        self.assertEqual(403, result.status_code)

    @patch('oio_rest.views.tokens.get_token')
    def test_route_get_token_post_returns_200_and_token_on_success(
            self,
            mock_get_token):
        # Arrange
        mock_get_token.return_value = 'testtoken'

        # Act
        result = self.app.post('/get-token',
                               data={'username': 'user', 'password': 'pass'})

        # Assert
        self.assertEqual(200, result.status_code)
        self.assertEqual(b'testtoken', result.data)
