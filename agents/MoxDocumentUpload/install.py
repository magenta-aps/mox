#!/usr/bin/python

import argparse
import os
import sys
from installutils import VirtualEnv, WSGI

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))
WSGIDIR = '/var/www/wsgi'

parser = argparse.ArgumentParser(description='Install MoxDocumentUpload')

parser.add_argument('-y', '--overwrite-virtualenv', action='store_true')
parser.add_argument('-n', '--keep-virtualenv', action='store_true')

args = parser.parse_args()

# ------------------------------------------------------------------------------

logfilename = "%s/install.log" % DIR
fp = open(logfilename, 'w')
fp.close()

virtualenv = VirtualEnv(DIR + "/python-env")
created = virtualenv.create(
    args.overwrite_virtualenv, args.keep_virtualenv, logfilename
)
if created:
    print "Running setup.py"
    virtualenv.run([DIR + "/setup.py", "develop"], logfilename)
    virtualenv.add_moxlib_pointer()

# ------------------------------------------------------------------------------

# Install WSGI service
print "Setting up moxdocumentupload WSGI service for Apache"
wsgi = WSGI(
    "setup/moxdocumentupload.wsgi.in",
    "setup/moxdocumentupload.conf.in",
    virtualenv
)
wsgi.install(True)
