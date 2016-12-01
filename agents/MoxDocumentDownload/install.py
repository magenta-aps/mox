#!/usr/bin/python

import argparse
import os
import sys
import subprocess
from installutils import VirtualEnv

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))
MOXDIR = os.path.abspath(DIR + "/../..")
WSGIDIR = '/var/www/wsgi'

parser = argparse.ArgumentParser(description='Install MoxWiki')

parser.add_argument('-y', '--overwrite-virtualenv', action='store_true')
parser.add_argument('-n', '--keep-virtualenv', action='store_true')

args = parser.parse_args()

# ------------------------------------------------------------------------------

logfilename = "%s/install.log" % DIR
fp = open(logfilename, 'w')
fp.close()

virtualenv = VirtualEnv(DIR + "/python-env")
created = virtualenv.create(args.overwrite_virtualenv, args.keep_virtualenv, logfilename)
if created:
    print "Running setup.py"
    virtualenv.run(logfilename, "python " + DIR + "/setup.py develop")
    virtualenv.add_moxlib_pointer(MOXDIR)

# ------------------------------------------------------------------------------

# Install WSGI service
print "Setting up moxdocumentdownload WSGI service for Apache"

if not os.path.exists(WSGIDIR):
    subprocess.Popen(['sudo', 'mkdir', "--parents", WSGIDIR]).wait()
subprocess.Popen(['sudo', 'cp', '--remove-destination', "%s/setup/moxdocumentdownload.wsgi" % DIR, WSGIDIR]).wait()
subprocess.Popen(['sudo', "%s/apache/set_include.sh" % MOXDIR, '-a', "%s/setup/moxdocumentdownload.conf" % DIR]).wait()

