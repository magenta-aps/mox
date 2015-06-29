from onelogin.saml2.utils import OneLogin_Saml2_Utils
from lxml import etree
from base64 import b64decode

with open('../test_auth_data/sample-saml2-assertion.xml') as f:
    assertion_body = f.read()

nsmap = {'ds': 'http://www.w3.org/2000/09/xmldsig#'}

with open("../test_auth_data/sample-idp-metadata.xml", "rb") as fh:
    cert = etree.parse(fh).find("//ds:X509Certificate", namespaces=nsmap).text

print "Validating using OneLogin_Saml2_Utils against cert %s" % cert

fingerprint = None
fingerprintalg = None
result = OneLogin_Saml2_Utils.validate_sign(assertion_body,
                                            cert, fingerprint,
                                            fingerprintalg, debug=True)
print "Result: %s" % result

# Try using signxml library

from lxml import etree
from base64 import b64decode
from signxml import xmldsig

print
print "Validating using signxml"
assertion_data = xmldsig(assertion_body).verify(x509_cert=cert)
print "Result:" + assertion_data
