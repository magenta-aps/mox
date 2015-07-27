from base64 import b64decode
from functools import wraps
import os
from flask import request, Response
from werkzeug.exceptions import Unauthorized
import zlib
from auth.saml2 import Saml2_Assertion
from settings import SAML_IDP_CERTIFICATE, SAML_MOX_ENTITY_ID
from settings import SAML_IDP_ENTITY_ID, USE_SAML_AUTHENTICATION

# Read the IdP certificate file into memory
with open(os.path.join(os.path.dirname(os.path.realpath(__file__)),
                       SAML_IDP_CERTIFICATE)) as f:
    __IDP_CERT = f.read()


def get_idp_cert():
    """Return the IdP's certificate being used to validate SAML tokens."""
    return __IDP_CERT


def check_saml_authentication():
    """Checks the Authorization header for a SAML token and validates it.

    The following Authorization header formats are supported:
        Authorization: SAML-GZIPPED <base64-encoded gzipped SAML assertion>

    If the token is not present, or is not valid, raises an
    `werkzeug.exceptions.Unauthorized` exception."""
    auth_header = request.headers.get('Authorization')
    if auth_header is None:
        raise Unauthorized("No Authorization header present")
    else:
        print auth_header

    # In Python, s.split(None) means "split on one or more whitespace chars".
    (auth_type, encoded_token) = auth_header.split(None, 1)
    auth_type = auth_type.lower()
    if auth_type != 'saml-gzipped':
        raise Unauthorized("Unknown authorization type %s." % auth_type)

    token = zlib.decompress(b64decode(encoded_token))
    assertion = Saml2_Assertion(token, SAML_MOX_ENTITY_ID,
                                SAML_IDP_ENTITY_ID, get_idp_cert())

    try:
        assertion.check_validity()

        print "Assertion valid"
        name_id = assertion.get_nameid()
        print "Name ID: %s" % name_id

        # Add the username and SAML attributes to the request object
        request.saml_user_id = name_id
        request.saml_attributes = assertion.get_attributes()
    except Exception as e:
        errmsg = "SAML token validation failed: %s" % e.message
        print errmsg
        raise Unauthorized(errmsg)


def requires_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if USE_SAML_AUTHENTICATION:
            check_saml_authentication()
        return f(*args, **kwargs)

    return decorated
