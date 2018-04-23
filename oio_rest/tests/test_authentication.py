from unittest import TestCase

import flask
import freezegun
from mock import MagicMock, patch

from oio_rest import authentication
from oio_rest.custom_exceptions import (AuthorizationFailedException,
                                        UnauthorizedException)

from . import util


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
        with self.app.test_request_context(headers=headers), self.assertRaises(
                AuthorizationFailedException):
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
        with self.app.test_request_context(headers=headers), self.assertRaises(
                AuthorizationFailedException):
            authentication.check_saml_authentication()


@patch('oio_rest.settings.USE_SAML_AUTHENTICATION', True)
class TestAssertionVerification(util.TestCase):
    '''The intention of these tests are that they should perform an actual
    validation. Unfortunately, I only had some old assertions
    available which I couldn't get to validate properly, so instead it
    merely tests those failures for now.

    '''

    @patch('oio_rest.settings.SAML_IDP_TYPE', 'adfs')
    @patch('oio_rest.settings.SAML_MOX_ENTITY_ID',
           'https://aak-modn.lxc')
    @patch('oio_rest.settings.SAML_IDP_ENTITY_ID',
           'http://fs.magenta-aps.dk/adfs/services/trust')
    @patch('oio_rest.settings.SAML_IDP_CERTIFICATE',
           util.get_fixture('adfs-cert.pem'))
    @freezegun.freeze_time('2017-08-10 11:07:30')
    def test_adfs(self):
        self.assertRequestResponse(
            '/organisation/organisation?bvn=%',
            {
                u'message': u'SAML token validation failed: '
                'Signature validation failed. SAML Response rejected',
            },
            headers={
                'Authorization': util.get_fixture('adfs-assertion.txt'),
            },
            status_code=403,
        )

    @patch('oio_rest.settings.SAML_IDP_TYPE', 'wso2')
    @patch('oio_rest.settings.SAML_MOX_ENTITY_ID',
           'https://aak-modn.lxc')
    @patch('oio_rest.settings.SAML_IDP_ENTITY_ID',
           'https://localhost')
    @patch('oio_rest.settings.SAML_IDP_CERTIFICATE',
           util.get_fixture('wso2-cert.pem'))
    @freezegun.freeze_time('2017-08-09 12:40')
    def test_wso2(self):
        self.assertRequestResponse(
            '/organisation/organisation?bvn=%',
            {
                u'message': u'SAML token validation failed: '
                'Signature validation failed. SAML Response rejected',
            },
            headers={
                'Authorization': util.get_fixture('wso2-assertion.txt'),
            },
            status_code=403,
        )
