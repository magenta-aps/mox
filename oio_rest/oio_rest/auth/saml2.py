from onelogin.saml2.utils import OneLogin_Saml2_Utils, print_xmlsec_errors
from onelogin.saml2.response import OneLogin_Saml2_Response
from defusedxml.lxml import fromstring
from copy import deepcopy


from xml.dom.minidom import Document, Element
from lxml import etree
from onelogin.saml2.constants import OneLogin_Saml2_Constants

# Initialize xmlsec only once!
# If not, this is not only not efficient, but also
# seems to cause problems with signature validation when many
# requests are made rapidly from different server processes.
import dm.xmlsec.binding as xmlsec
xmlsec.initialize()

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
        if not validate_sign(self.original_document,
                            self.idp_cert,
                            fingerprint,
                            fingerprintalg,
                            debug=True):
            raise Exception(
                'Signature validation failed. SAML Response rejected')


# This code was pulled from OneLogin's util.py
# The only change was to remove xmlsec.initialize()
def validate_sign(xml, cert=None, fingerprint=None, fingerprintalg='sha1', validatecert=False, debug=False):
    """
    Validates a signature (Message or Assertion).

    :param xml: The element we should validate
    :type: string | Document

    :param cert: The pubic cert
    :type: string

    :param fingerprint: The fingerprint of the public cert
    :type: string

    :param fingerprintalg: The algorithm used to build the fingerprint
    :type: string

    :param validatecert: If true, will verify the signature and if the cert is valid.
    :type: bool

    :param debug: Activate the xmlsec debug
    :type: bool
    """
    try:
        if xml is None or xml == '':
            raise Exception('Empty string supplied as input')
        elif isinstance(xml, etree._Element):
            elem = xml
        elif isinstance(xml, Document):
            xml = xml.toxml()
            elem = fromstring(str(xml))
        elif isinstance(xml, Element):
            xml.setAttributeNS(
                unicode(OneLogin_Saml2_Constants.NS_SAMLP),
                'xmlns:samlp',
                unicode(OneLogin_Saml2_Constants.NS_SAMLP)
            )
            xml.setAttributeNS(
                unicode(OneLogin_Saml2_Constants.NS_SAML),
                'xmlns:saml',
                unicode(OneLogin_Saml2_Constants.NS_SAML)
            )
            xml = xml.toxml()
            elem = fromstring(str(xml))
        elif isinstance(xml, basestring):
            elem = fromstring(str(xml))
        else:
            raise Exception('Error parsing xml string')

        if debug:
            xmlsec.set_error_callback(print_xmlsec_errors)

        xmlsec.addIDs(elem, ["ID"])

        signature_nodes = OneLogin_Saml2_Utils.query(elem, '//ds:Signature')

        if len(signature_nodes) > 0:
            signature_node = signature_nodes[0]

            if (cert is None or cert == '') and fingerprint:
                x509_certificate_nodes = OneLogin_Saml2_Utils.query(signature_node, '//ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509Certificate')
                if len(x509_certificate_nodes) > 0:
                    x509_certificate_node = x509_certificate_nodes[0]
                    x509_cert_value = x509_certificate_node.text
                    x509_fingerprint_value = OneLogin_Saml2_Utils.calculate_x509_fingerprint(x509_cert_value, fingerprintalg)
                    if fingerprint == x509_fingerprint_value:
                        cert = OneLogin_Saml2_Utils.format_cert(x509_cert_value)

            if cert is None or cert == '':
                return False

            dsig_ctx = xmlsec.DSigCtx()

            file_cert = OneLogin_Saml2_Utils.write_temp_file(cert)

            if validatecert:
                mngr = xmlsec.KeysMngr()
                mngr.loadCert(file_cert.name, xmlsec.KeyDataFormatCertPem, xmlsec.KeyDataTypeTrusted)
                dsig_ctx = xmlsec.DSigCtx(mngr)
            else:
                dsig_ctx = xmlsec.DSigCtx()
                dsig_ctx.signKey = xmlsec.Key.load(file_cert.name, xmlsec.KeyDataFormatCertPem, None)

            file_cert.close()

            dsig_ctx.setEnabledKeyData([xmlsec.KeyDataX509])
            dsig_ctx.verify(signature_node)
            return True
        else:
            return False
    except Exception:
        return False
