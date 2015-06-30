#!/usr/bin/env python

import sys
from base64 import b64encode

# Outputs the Authorization headers for the given SAML assertion token

if len(sys.argv) > 1:
    assertion_file = sys.argv[1]
else:
    assertion_file = 'test_auth_data/sample-saml2-assertion.xml'

with open(assertion_file) as f:
    assertion_body = f.read()

import zlib

print "Authorization: saml-gzipped %s" % b64encode(
    zlib.compress(assertion_body))
