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
