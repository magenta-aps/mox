from unittest import TestCase

import sys

import requests
from mock import patch, MagicMock, mock

from oio_rest.auth import tokens


class TestTokens(TestCase):
    @patch('oio_rest.auth.tokens.etree.tostring')
    @patch('oio_rest.auth.tokens.requests')
    @patch('oio_rest.auth.tokens.jinja_env')
    def test_get_token_pretty_printed(self, mock_jinja_env, mock_requests,
                                      mock_etree_tostring):
        # type: (MagicMock, MagicMock, MagicMock) -> None
        # Arrange
        username = ''
        passwd = ''

        mock_requests.post.return_value = resp = MagicMock()
        resp.ok = True
        resp.content = '''
        <Body>
            <RequestSecurityTokenResponse>
                <RequestedSecurityToken>
                    <Assertion whatever='1'></Assertion>
                </RequestedSecurityToken>
            </RequestSecurityTokenResponse>
        </Body>
        '''

        # Act
        tokens.get_token(username, passwd, pretty_print=True)

        # Assert
        mock_etree_tostring.assert_called_with(mock.ANY, pretty_print=True)

    @patch('oio_rest.auth.tokens.requests')
    @patch('oio_rest.auth.tokens.jinja_env')
    def test_get_token(self, mock_jinja_env, mock_requests):
        # type: (MagicMock, MagicMock) -> None
        # Arrange
        username = ''
        passwd = ''

        mock_requests.post.return_value = resp = MagicMock()
        resp.ok = True
        resp.content = '''
        <Body>
            <RequestSecurityTokenResponse>
                <RequestedSecurityToken>
                    <Assertion whatever='1'></Assertion>
                </RequestedSecurityToken>
            </RequestSecurityTokenResponse>
        </Body>
        '''

        expected_result = ('saml-gzipped H4sIAAAAAAAAA7NxLC5OLSrJzM9TKM9I'
                           'LEktSy2yVTJU0rfjUkADALryg9gqAAAA')

        # Act
        actual_result = tokens.get_token(username, passwd)

        # Assert
        self.assertEqual(expected_result, actual_result)

    @patch('oio_rest.auth.tokens.requests')
    @patch('oio_rest.auth.tokens.jinja_env')
    def test_get_token_raises_on_response_code_500(self, mock_jinja_env,
                                                   mock_requests):
        # type: (MagicMock, MagicMock) -> None
        # Arrange
        username = ''
        passwd = ''

        mock_requests.post.return_value = resp = MagicMock()
        resp.ok = False
        resp.headers.get.return_value = ('application/soap+xml')
        resp.status_code = 500

        resp.content = '''
        <Envelope>
            <Body>
                <RequestSecurityTokenResponse>
                    <RequestedSecurityToken>
                        <Assertion whatever='1'></Assertion>
                    </RequestedSecurityToken>
                </RequestSecurityTokenResponse>
            </Body>
        </Envelope>
        '''

        # Act
        with self.assertRaises(Exception):
            tokens.get_token(username, passwd)

    @patch('oio_rest.auth.tokens.requests')
    @patch('oio_rest.auth.tokens.jinja_env')
    def test_get_token_raises_on_fault(self, mock_jinja_env,
                                       mock_requests):
        # type: (MagicMock, MagicMock) -> None
        # Arrange
        username = ''
        passwd = ''

        mock_requests.post.return_value = resp = MagicMock()
        resp.ok = True

        resp.content = '''
        <Envelope>
            <Body>
                <Fault></Fault>
            </Body>
        </Envelope>
        '''

        # Act
        with self.assertRaises(Exception):
            tokens.get_token(username, passwd)

    @patch('oio_rest.auth.tokens.requests')
    @patch('oio_rest.auth.tokens.jinja_env')
    def test_get_token_raises_on_no_tokens(self, mock_jinja_env,
                                           mock_requests):
        # type: (MagicMock, MagicMock) -> None
        # Arrange
        username = ''
        passwd = ''

        mock_requests.post.return_value = resp = MagicMock()
        resp.ok = True

        resp.content = '''
        <Envelope>
            <Body>
                <RequestSecurityTokenResponse>
                    <RequestedSecurityToken>
                    </RequestedSecurityToken>
                </RequestSecurityTokenResponse>
            </Body>
        </Envelope>
        '''

        # Act
        with self.assertRaises(KeyError):
            tokens.get_token(username, passwd)

    @patch('oio_rest.auth.tokens.requests')
    @patch('oio_rest.auth.tokens.jinja_env')
    def test_get_token_raises_on_too_many_tokens(self, mock_jinja_env,
                                                 mock_requests):
        # type: (MagicMock, MagicMock) -> None
        # Arrange
        username = ''
        passwd = ''

        mock_requests.post.return_value = resp = MagicMock()
        resp.ok = True

        resp.content = '''
        <Envelope>
            <Body>
                <RequestSecurityTokenResponse>
                    <RequestedSecurityToken>
                        <Assertion whatever='1'></Assertion>
                        <Assertion whatever='1'></Assertion>
                    </RequestedSecurityToken>
                </RequestSecurityTokenResponse>
            </Body>
        </Envelope>
        '''

        # Act
        with self.assertRaises(KeyError):
            tokens.get_token(username, passwd)

    @patch('oio_rest.auth.tokens.requests')
    @patch('oio_rest.auth.tokens.jinja_env')
    def test_get_token_raises_stored_response_error(self, mock_jinja_env,
                                                    mock_requests):
        from requests import HTTPError

        # type: (MagicMock, MagicMock) -> None
        # Arrange
        username = ''
        passwd = ''

        mock_requests.post.return_value = resp = MagicMock()
        resp.ok = False
        resp.raise_for_status.side_effect = HTTPError

        resp.content = '''
        <Envelope>
            <Body>
                <RequestSecurityTokenResponse>
                    <RequestedSecurityToken>
                        <Assertion whatever='1'></Assertion>
                        <Assertion whatever='1'></Assertion>
                    </RequestedSecurityToken>
                </RequestSecurityTokenResponse>
            </Body>
        </Envelope>
        '''

        # Act
        with self.assertRaises(HTTPError):
            tokens.get_token(username, passwd)

    @patch('oio_rest.auth.tokens.get_token')
    def test_main_returns_1_on_sslerror(self, mock_get_token):
        # Arrange
        args = ['prog', '-u', 'user', '-p', 'pass']

        mock_get_token.side_effect = requests.exceptions.SSLError

        # Act
        with patch.object(sys, 'argv', args):
            actual_code = tokens.main()

        # Assert
        self.assertEqual(1, actual_code)

    @patch('sys.stdout.write')
    @patch('oio_rest.auth.tokens.get_token')
    def test_main(self, mock_get_token, mock_write):
        # Arrange
        args = ['prog', '-u', 'user', '-p', 'pass']

        mock_get_token.return_value = 'test token'

        # Act
        with patch.object(sys, 'argv', args):
            actual_code = tokens.main()

        # Assert
        self.assertEqual(0, actual_code)
        mock_write.assert_called_with('test token')

    @patch('ssl.DER_cert_to_PEM_cert')
    @patch('oio_rest.auth.tokens.base64.standard_b64decode')
    @patch('sys.stdout.write')
    @patch('oio_rest.auth.tokens.get_token')
    def test_main_cert_only(self, mock_get_token, mock_write,
                            mock_base64_decode, mock_ssl_d2p):
        # Arrange
        args = ['prog', '-u', 'user', '-p', 'pass', '--cert-only']

        mock_get_token.return_value = ('<X509Data><X509Certificate>test token'
                                       '</X509Certificate></X509Data>')
        mock_base64_decode.side_effect = lambda x: x
        mock_ssl_d2p.side_effect = lambda x: x

        # Act
        with patch.object(sys, 'argv', args):
            actual_code = tokens.main()

        # Assert
        self.assertEqual(0, actual_code)
        mock_write.assert_called_with('test token')
        mock_base64_decode.assert_called()
        mock_ssl_d2p.assert_called()

    @patch('requests.packages.urllib3.disable_warnings')
    @patch('oio_rest.auth.tokens.get_token')
    def test_main_insecure_disables_warnings(self, mock_get_token,
                                             mock_urllib3_dw):
        # Arrange
        args = ['prog', '-u', 'user', '-p', 'pass', '--insecure']

        mock_get_token.return_value = 'test token'

        # Act
        with patch.object(sys, 'argv', args):
            actual_code = tokens.main()

        # Assert
        self.assertEqual(0, actual_code)
        mock_urllib3_dw.assert_called()
