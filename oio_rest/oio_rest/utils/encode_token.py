# Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


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
