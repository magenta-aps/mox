#!/usr/bin/python

import argparse
import os
import sys
from installutils import VirtualEnv, WSGI

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))
MOXDIR = os.path.abspath(DIR + "/../..")
WSGIDIR = '/var/www/wsgi'

parser = argparse.ArgumentParser(description='Install MoxDocumentDownload')

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
    virtualenv.run(logfilename, "python " + DIR + "/setup.py develop")
    virtualenv.add_moxlib_pointer(MOXDIR)

# ------------------------------------------------------------------------------

# Install WSGI service
print "Setting up moxdocumentdownload WSGI service for Apache"
wsgi = WSGI(
    "%s/setup/moxdocumentdownload.wsgi" % DIR,
    "%s/setup/moxdocumentdownload.conf" % DIR
)
wsgi.install(True)
