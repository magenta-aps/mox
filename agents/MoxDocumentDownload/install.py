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

virtualenv = VirtualEnv(DIR + "/python-env")
created = virtualenv.create(
    args.overwrite_virtualenv, args.keep_virtualenv,
)
if created:
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
