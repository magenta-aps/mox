# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
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

parser = argparse.ArgumentParser(description='Install MoxDocumentDownload')

parser.add_argument('-y', '--overwrite-virtualenv', action='store_true')
parser.add_argument('-n', '--keep-virtualenv', action='store_true')

args = parser.parse_args()

# ------------------------------------------------------------------------------

virtualenv = VirtualEnv()
print "Running setup.py"
virtualenv.run(DIR + "/setup.py", "develop")
virtualenv.add_moxlib_pointer()

# ------------------------------------------------------------------------------

# Install WSGI service
print "Setting up moxdocumentdownload WSGI service for Apache"
wsgi = WSGI(
    "setup/moxdocumentdownload.wsgi.in",
    "setup/moxdocumentdownload.conf.in",
    virtualenv,
)
wsgi.install(True)
