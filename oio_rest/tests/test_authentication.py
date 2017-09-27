from unittest import TestCase

import flask
from mock import patch, MagicMock

from oio_rest import authentication
from oio_rest.custom_exceptions import UnauthorizedException, \
    AuthorizationFailedException


class TestAuthentication(TestCase):
    def setUp(self):
        self.app = flask.Flask(__name__)

    def test_check_saml_authentication_raises_on_no_auth(self):
        # Act & Assert
        with self.app.test_request_context(), \
             self.assertRaises(UnauthorizedException):
            authentication.check_saml_authentication()

    def test_check_saml_authentication_raises_on_unknown_auth(self):
        # Arrange
        headers = {'Authorization': 'unknowntype token'}

        # Act & Assert
        with self.app.test_request_context(headers=headers), \
             self.assertRaises(AuthorizationFailedException):
            authentication.check_saml_authentication()

    @patch('oio_rest.authentication.Saml2_Assertion')
    @patch('oio_rest.authentication.b64decode', new=MagicMock())
    @patch('oio_rest.authentication.zlib', new=MagicMock())
    def test_check_saml_authentication_raises_on_invalid_assert(self,
                                                                mock_saml2):
        # Arrange
        headers = {'Authorization': 'saml-gzipped token'}

        mock_saml2.return_value.check_validity.side_effect = Exception

        # Act & Assert
        with self.app.test_request_context(headers=headers), \
             self.assertRaises(AuthorizationFailedException):
            authentication.check_saml_authentication()

