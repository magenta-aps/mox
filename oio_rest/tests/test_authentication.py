import unittest

import flask
import freezegun
from mock import MagicMock, patch

from oio_rest import authentication
from oio_rest.custom_exceptions import (AuthorizationFailedException,
                                        UnauthorizedException)

from tests import util


class TestAuthentication(unittest.TestCase):
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


@patch('settings.USE_SAML_AUTHENTICATION', True)
class TestAssertionVerification(util.TestCase):
    '''The intention of these tests are that they should perform an actual
    validation. Unfortunately, I only had some old assertions
    available which I couldn't get to validate properly, so instead it
    merely tests those failures for now.

    '''

    @patch('settings.SAML_IDP_TYPE', 'adfs')
    @patch('settings.SAML_MOX_ENTITY_ID',
           'https://moxdev.atlas.magenta.dk')
    @patch('settings.SAML_IDP_ENTITY_ID',
           'http://adfs.magenta.dk/adfs/services/trust')
    @patch('settings.SAML_IDP_URL',
           "https://adfs.magenta.dk/adfs/services/trust/13/UsernameMixed")
    @patch('settings.SAML_USER_ID_ATTIBUTE',
           "http://schemas.xmlsoap.org/ws/2005/05/"
           "identity/claims/privatepersonalidentifier")
    @patch('oio_rest.authentication.__IDP_CERT',
           util.get_fixture('adfs-cert.pem'))
    def test_adfs(self):
        def check(expected, status_code):
            token = util.get_fixture('adfs-assertion.txt').strip()
            self.assertRequestResponse(
                '/organisation/organisation?bvn=%',
                expected,
                headers={
                    'Authorization': token,
                },
                status_code=status_code,
            )

        with freezegun.freeze_time('2018-04-20 18:00:00'):
            # this test verifies a properly authorised request
            check(
                {
                    'results': [[]],
                },
                200,
            )

            # now verify that we reject assertions not targeted to us

            with patch('settings.SAML_MOX_ENTITY_ID',
                       'https://whatever'):
                check(
                    {
                        'message':
                        'SAML token validation failed: '
                        'https://whatever is not a valid audience for this '
                        'Assertion, got https://moxdev.atlas.magenta.dk',
                    },
                    403,
                )

            # verify that we reject from the wrong issuing IdP

            with patch('settings.SAML_IDP_ENTITY_ID',
                       'https://whatever'):
                check(
                    {
                        'message':
                        "SAML token validation failed: "
                        "Invalid issuer "
                        "'http://adfs.magenta.dk/adfs/services/trust' "
                        "in the Assertion/Response, expected "
                        "'https://whatever'"
                    },
                    403,
                )

            # and we MUST verify the certificate!!!

            with patch('oio_rest.authentication.__IDP_CERT',
                       util.get_fixture('idp-certificate.pem')):
                check(
                    {
                        'message':
                        'SAML token validation failed: '
                        'Signature validation failed. SAML Response rejected. '
                        'Signature is invalid.',
                    },
                    403,
                )

        # finally, ensure that we reject expired requests

        with freezegun.freeze_time('2018-04-20 19:00:00'):
            check(
                {
                    'message':
                    'SAML token validation failed: '
                    'Could not validate timestamp: expired. '
                    'Check system clock.'
                },
                403,
            )

        # ..and just-in-case, that we reject future requests as well

        with freezegun.freeze_time('2018-04-20 17:00:00'):
            check(
                {
                    'message':
                    'SAML token validation failed: '
                    'Could not validate timestamp: not yet valid. '
                    'Check system clock.'
                },
                403,
            )

    @patch('settings.SAML_IDP_TYPE', 'wso2')
    def test_wso2(self):
        raise unittest.SkipTest('TODO')

    def test_restrictions(self):
        raise unittest.SkipTest('TODO')
