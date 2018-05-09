#!/usr/bin/env python

import sys
import shutil
import os
import tempfile
from base64 import b64encode
import gzip

# Outputs the Authorization headers for the given SAML assertion token

if len(sys.argv) > 1:
    assertion_file = sys.argv[1]
else:
    assertion_file = 'test_auth_data/sample-saml2-assertion.xml'

(handle, tmpfilename) = tempfile.mkstemp('.gz')

with open(assertion_file, 'rb') as f_in, gzip.open(tmpfilename, "wb") as f_out:
    shutil.copyfileobj(f_in, f_out)

with open(tmpfilename) as f:
    zipped_data = f.read()

print("Authorization: saml-gzipped %s" % b64encode(zipped_data))

os.remove(tmpfilename)
