# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


import base64

from onelogin.saml2.utils import OneLogin_Saml2_Utils
from onelogin.saml2.response import OneLogin_Saml2_Response
from defusedxml.lxml import fromstring

from onelogin.saml2.settings import OneLogin_Saml2_Settings


class Saml2_Assertion(OneLogin_Saml2_Response):
    """Represent a SAML2 assertion by wrapping it in OneLogin's Response class.

    We reuse many of OneLogin_Saml2_Response's methods.
    """
    def __init__(self, assertion_xml, mox_entity_id, idp_entity_id, idp_url,
                 idp_cert):
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

        document = fromstring(assertion_xml)
        if document.tag != '{urn:oasis:names:tc:SAML:2.0:protocol}Response':
            # OneLogin's methods expect the data wrapped in a Response element,
            # so we fake it here.
            response = """
            <samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                            xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">
                {}
            </samlp:Response>""".format(assertion_xml)

            document = fromstring(response)
            self.response = response.encode('ascii')
        else:
            self.response = assertion_xml

        self.original_document = document

        super(Saml2_Assertion, self).__init__(
            OneLogin_Saml2_Settings(
                {
                    'sp': {
                        'entityId': mox_entity_id,
                        'assertionConsumerService': {
                            'url': idp_url,
                        },
                        'x509cert': idp_cert,
                    },
                    'idp': {
                        'entityId': idp_entity_id,
                    },
                },
                sp_validation_only=True,
            ),
            base64.b64encode(self.response),
        )

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
        self.validate_timestamps(raise_exceptions=True)

        # Checks audience
        valid_audiences = self.get_audiences()
        if valid_audiences and self.mox_entity_id not in valid_audiences:
            raise Exception(
                '%s is not a valid audience for this Assertion, got %s' %
                (self.mox_entity_id, ', '.join(valid_audiences))
            )

        # Checks the issuers
        issuers = self.get_issuers()
        for issuer in issuers:
            if issuer is None or issuer != self.idp_entity_id:
                raise Exception(
                    'Invalid issuer {!r} in the Assertion/Response, '
                    'expected {!r}'.format(issuer, self.idp_entity_id)
                )
        fingerprint = None
        fingerprintalg = None

        if not OneLogin_Saml2_Utils.validate_sign(
            self.original_document,
            self.idp_cert,
            fingerprint,
            fingerprintalg,
            debug=True,
            raise_exceptions=True,
        ):
            raise Exception(
                'Signature validation failed. SAML Response rejected')
