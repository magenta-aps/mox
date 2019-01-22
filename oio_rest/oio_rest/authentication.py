# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import os
import zlib
import uuid
from base64 import b64decode
from functools import wraps

from flask import request
import flask_saml_sso

from .custom_exceptions import UnauthorizedException
from .custom_exceptions import AuthorizationFailedException
from .auth.saml2 import Saml2_Assertion

from . import settings


# Read the IdP certificate file into memory
with open(os.path.join(os.path.dirname(os.path.realpath(__file__)),
                       settings.SAML_IDP_CERTIFICATE)) as f:
    __IDP_CERT = f.read()


def get_idp_cert():
    """Return the IdP's certificate being used to validate SAML tokens."""
    return __IDP_CERT


def check_saml_authentication():
    """Checks the Authorization header for a SAML token and validates it.

    The following Authorization header formats are supported:
        Authorization: SAML-GZIPPED <base64-encoded gzipped SAML assertion>

    Raises `UnauthorizedException` when the token is absent, and
    `AuthorizationFailedException` when it's invalid.

    """
    auth_header = request.headers.get('Authorization')
    if auth_header is None:
        raise UnauthorizedException("No Authorization header present")

    # In Python, s.split(None) means "split on one or more whitespace chars".
    (auth_type, encoded_token) = auth_header.split(None, 1)
    auth_type = auth_type.lower()
    if auth_type != 'saml-gzipped':
        raise AuthorizationFailedException(
            "Unknown authorization type %s." % auth_type
        )

    binary_token = b64decode(encoded_token)

    # There are subtle differences between zlib and gzip, which is why we
    # can't just do
    # token = zlib.decompress(binary_token)
    # We must do this instead:
    decompressor = zlib.decompressobj(16 + zlib.MAX_WBITS)
    token = decompressor.decompress(binary_token)
    # See
    # https://rationalpie.wordpress.com/2010/06/02/
    #           python-streaming-gzip-decompression/

    assertion = Saml2_Assertion(token, settings.SAML_MOX_ENTITY_ID,
                                settings.SAML_IDP_ENTITY_ID,
                                settings.SAML_IDP_URL,
                                get_idp_cert())

    try:
        assertion.check_validity()

        name_id = assertion.get_nameid()
        print("SAML Assertion valid for: %s" % name_id)

        # Add the username and SAML attributes to the request object
        request.saml_attributes = assertion.get_attributes()

        userid = request.saml_attributes[
            settings.SAML_USER_ID_ATTIBUTE
        ][0]

        # Active Directory sends the UUID as a Base64-encoded string
        if len(userid) == 24:
            userid = str(uuid.UUID(bytes_le=b64decode(userid)))

        request.saml_user_id = userid

        # print "UUID", request.saml_user_id
        # print "SAML ATTRIBUTES",
        #       json.dumps(request.saml_attributes, indent=2)
        # print "TOKEN: ", token
    except Exception as e:
        errmsg = "SAML token validation failed: {}".format(
            e.args and e.args[0] or str(e)
        )
        raise AuthorizationFailedException(errmsg)


def requires_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if settings.USE_SAML_AUTHENTICATION:
            check_saml_authentication()
        elif settings.SAML_AUTH_ENABLE:
            flask_saml_sso.check_saml_authentication()
        return f(*args, **kwargs)

    return decorated


def get_authenticated_user():
    """Return hardcoded UUID if authentication is switched off."""
    if settings.USE_SAML_AUTHENTICATION:
        return request.saml_user_id
    else:
        return "42c432e8-9c4a-11e6-9f62-873cf34a735f"
