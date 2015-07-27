from onelogin.saml2.utils import OneLogin_Saml2_Utils
from onelogin.saml2.response import OneLogin_Saml2_Response
from defusedxml.lxml import fromstring
from copy import deepcopy


class Saml2_Assertion(OneLogin_Saml2_Response):
    """Represent a SAML2 assertion by wrapping it in OneLogin's Response class.

    We reuse many of OneLogin_Saml2_Response's methods.
    """
    def __init__(self, assertion_xml, mox_entity_id, idp_entity_id, idp_cert):
        """Initialize with the assertion XML, and various parameters.

        :param assertion_xml: The Assertion XML.
        :type assertion_xml: String

        :param mox_entity_id: The entity ID of the MOX service. Used in
                              checking the AudienceRestriction.
        :type mox_entity_id: String

        :param idp_entity_id: The entity ID of the IdP. Used in checking the
                              Issuer of the Assertion.
        :type idp_entity_id: String

        :param idp_cert: The certificate of the IdP, as PEM formatted string.
        :type idp_cert: String
        """
        self.mox_entity_id = mox_entity_id
        self.idp_entity_id = idp_entity_id
        self.idp_cert = idp_cert

        # We don't actually provide or use any settings object
        self.__settings = None
        self.__error = None

        # OneLogin's methods expect the data wrapped in a Response element,
        # so we fake it here.
        self.response = """
        <samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                        xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">
            %s
        </samlp:Response>""" % assertion_xml

        self.original_document = fromstring(self.response)

        # OneLogin's methods expect the saml namespace, not the saml2
        # namespace, so we simply replace it here.
        self.document = fromstring(
            self.response.replace("<saml2:", "<saml:").replace("</saml2:",
                                                               "</saml:")
        )
        self.decrypted_document = None
        self.encrypted = None

        # Quick check for the presence of EncryptedAssertion
        encrypted_assertion_nodes = self.__query(
            '/samlp:Response/saml:EncryptedAssertion')
        if encrypted_assertion_nodes:
            decrypted_document = deepcopy(self.document)
            self.encrypted = True
            self.decrypted_document = self.__decrypt_assertion(
                decrypted_document)

    def __query(self, query):
        """Call the private __query method on the base class."""
        return self._OneLogin_Saml2_Response__query(query)

    def __query_assertion(self, xpath_expr):
        """Call the private __query_assertion method on the base class."""
        return self._OneLogin_Saml2_Response__query_assertion(xpath_expr)

    def check_validity(self):
        """Check if the assertion is valid. If not, raises Exception

        Checks if there are at least one AttributeStatement,
        valid timestamps in any Condition elements, valid audience,
        valid issuer, and finally, valid signature.
        """

        # Checks that there is at least one AttributeStatement
        attribute_statement_nodes = self.__query_assertion(
            '/saml:AttributeStatement')
        if not attribute_statement_nodes:
            raise Exception(
                'There is no AttributeStatement in the Assertion')

        # Validates Assertion timestamps
        if not self.validate_timestamps():
            raise Exception(
                'Timing issues (please check your clock settings)')

        # Checks audience
        valid_audiences = self.get_audiences()
        if valid_audiences and self.mox_entity_id not in valid_audiences:
            raise Exception(
                '%s is not a valid audience for this Assertion' %
                self.mox_entity_id)

        # Checks the issuers
        issuers = self.get_issuers()
        for issuer in issuers:
            if issuer is None or issuer != self.idp_entity_id:
                raise Exception('Invalid issuer in the Assertion/Response')

        fingerprint = None
        fingerprintalg = None
        if not OneLogin_Saml2_Utils.validate_sign(self.original_document,
                                                  self.idp_cert,
                                                  fingerprint,
                                                  fingerprintalg,
                                                  debug=True):
            raise Exception(
                'Signature validation failed. SAML Response rejected')
