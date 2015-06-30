from auth.saml2 import Saml2_Assertion

with open('../test_auth_data/sample-saml2-assertion.xml') as f:
    assertion_body = f.read()

with open("../test_auth_data/idp-certificate.pem") as f:
    cert = f.read()

MOX_ENTITY_ID = 'http://localhost:8000'
IDP_ENTITY_ID = 'localhost'
assertion = Saml2_Assertion(assertion_body, MOX_ENTITY_ID,
                            IDP_ENTITY_ID, cert)

if assertion.is_valid():
    print "Assertion valid"
    print "Username: %s" % assertion.get_nameid()
else:
    # TODO: Raise exception
    print "Assertion NOT valid!"
