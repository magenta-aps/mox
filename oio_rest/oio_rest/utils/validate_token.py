# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import sys

from .oio_rest.auth.saml2 import Saml2_Assertion
from .oio_rest.authentication import get_idp_cert

from settings import SAML_MOX_ENTITY_ID, SAML_IDP_ENTITY_ID


if len(sys.argv) > 1:
    assertion_file = sys.argv[1]
else:
    assertion_file = 'test_auth_data/sample-saml2-assertion.xml'

with open(assertion_file) as f:
    assertion_body = f.read()

assertion = Saml2_Assertion(assertion_body, SAML_MOX_ENTITY_ID,
                            SAML_IDP_ENTITY_ID, get_idp_cert())

try:
    assertion.check_validity()
    print("Assertion valid")
    print("Name ID: %s" % assertion.get_nameid())
except Exception as e:
    print("Assertion NOT valid!")
    print(str(e))
