# Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


#!/usr/bin/python

import argparse
import os
import sys
from installutils import VirtualEnv, WSGI

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))

parser = argparse.ArgumentParser(description='Install MoxDocumentUpload')

args = parser.parse_args()

# ------------------------------------------------------------------------------

virtualenv = VirtualEnv()
print "Running setup.py"
virtualenv.run(DIR + "/setup.py", "develop")
virtualenv.add_moxlib_pointer()

# ------------------------------------------------------------------------------

# Install WSGI service
print "Setting up moxdocumentupload WSGI service for Apache"
wsgi = WSGI(
    "setup/moxdocumentupload.wsgi.in",
    "setup/moxdocumentupload.conf.in",
    virtualenv,
)
wsgi.install(True)
