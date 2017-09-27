from unittest import TestCase

from mock import patch

from oio_rest.auth.saml2 import Saml2_Assertion


class TestSAML2(TestCase):
    def test_check_validity_raises_on_no_attribute_statement(self):
        # Arrange
        assertion_xml = ''
        mox_entity_id = ''
        idp_entity_id = ''
        idp_cert = ''

        s2a = Saml2_Assertion(assertion_xml, mox_entity_id, idp_entity_id,
                              idp_cert)

        # Act & Assert
        with self.assertRaises(Exception):
            s2a.check_validity()

    @patch('oio_rest.auth.saml2.Saml2_Assertion.validate_timestamps')
    def test_check_validity_raises_on_invalid_timestamp(self, mock_vt):
        # Arrange
        mock_vt.return_value = False

        assertion_xml = '<saml:Assertion><saml:AttributeStatement></saml:AttributeStatement></saml:Assertion>'
        mox_entity_id = ''
        idp_entity_id = ''
        idp_cert = ''

        s2a = Saml2_Assertion(assertion_xml, mox_entity_id, idp_entity_id,
                              idp_cert)

        # Act & Assert
        with self.assertRaises(Exception):
            s2a.check_validity()

    @patch('oio_rest.auth.saml2.Saml2_Assertion.get_audiences')
    @patch('oio_rest.auth.saml2.Saml2_Assertion.validate_timestamps')
    def test_check_validity_raises_on_invalid_audience(self, mock_vt, mock_ga):
        # Arrange
        mock_vt.return_value = True
        mock_ga.return_value = ['5678']

        assertion_xml = '<saml:Assertion><saml:AttributeStatement></saml:AttributeStatement></saml:Assertion>'
        mox_entity_id = '1234'
        idp_entity_id = ''
        idp_cert = ''

        s2a = Saml2_Assertion(assertion_xml, mox_entity_id, idp_entity_id,
                              idp_cert)

        # Act & Assert
        with self.assertRaises(Exception):
            s2a.check_validity()

    @patch('oio_rest.auth.saml2.Saml2_Assertion.get_issuers')
    @patch('oio_rest.auth.saml2.Saml2_Assertion.validate_timestamps')
    def test_check_validity_raises_on_invalid_issuer(self, mock_vt, mock_gi):
        # Arrange
        mock_vt.return_value = True
        mock_gi.return_value = [None]

        assertion_xml = '<saml:Assertion><saml:AttributeStatement></saml:AttributeStatement></saml:Assertion>'
        mox_entity_id = '1234'
        idp_entity_id = '5678'
        idp_cert = ''

        s2a = Saml2_Assertion(assertion_xml, mox_entity_id, idp_entity_id,
                              idp_cert)

        # Act & Assert
        with self.assertRaises(Exception):
            s2a.check_validity()

    @patch('oio_rest.auth.saml2.validate_sign')
    @patch('oio_rest.auth.saml2.Saml2_Assertion.get_issuers')
    @patch('oio_rest.auth.saml2.Saml2_Assertion.validate_timestamps')
    def test_check_validity_raises_on_invalid_signature(self, mock_vt, mock_gi,
                                                        mock_vs):
        # Arrange
        assertion_xml = '<saml:Assertion><saml:AttributeStatement></saml:AttributeStatement></saml:Assertion>'
        mox_entity_id = '1234'
        idp_entity_id = '5678'
        idp_cert = ''

        mock_vt.return_value = True
        mock_gi.return_value = [idp_entity_id]
        mock_vs.return_value = False

        s2a = Saml2_Assertion(assertion_xml, mox_entity_id, idp_entity_id,
                              idp_cert)

        # Act & Assert
        with self.assertRaises(Exception):
            s2a.check_validity()

    @patch('oio_rest.auth.saml2.validate_sign')
    @patch('oio_rest.auth.saml2.Saml2_Assertion.get_issuers')
    @patch('oio_rest.auth.saml2.Saml2_Assertion.validate_timestamps')
    def test_check_validity_raises_on_invalid_signature(self, mock_vt, mock_gi,
                                                        mock_vs):
        # Arrange
        assertion_xml = '<saml:Assertion><saml:AttributeStatement></saml:AttributeStatement></saml:Assertion>'
        mox_entity_id = '1234'
        idp_entity_id = '5678'
        idp_cert = ''

        mock_vt.return_value = True
        mock_gi.return_value = [idp_entity_id]
        mock_vs.return_value = False

        s2a = Saml2_Assertion(assertion_xml, mox_entity_id, idp_entity_id,
                              idp_cert)

        # Act & Assert
        with self.assertRaises(Exception):
            s2a.check_validity()
