#!/usr/bin/python

import argparse
import os
import sys
from installutils import VirtualEnv, WSGI, Folder, LogFile, install_dependencies

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))
MOXDIR = os.path.abspath(DIR + "/../..")
WSGIDIR = '/var/www/wsgi'
STORAGEDIR = '/var/mox'

parser = argparse.ArgumentParser(description='Install OIO Rest')

parser.add_argument('-y', '--overwrite-virtualenv', action='store_true')
parser.add_argument('-n', '--keep-virtualenv', action='store_true')

args = parser.parse_args()

# -----------------------------------------------------------------------------

install_log = LogFile("%s/install.log" % DIR)
install_log.create()

install_dependencies("%s/SYSTEM_DEPENDENCIES" % DIR)

# -----------------------------------------------------------------------------

# Create the MOX content storage directory and give the www-data user ownership
MOX_STORAGE = "/var/mox"
print "Creating MOX content storage directory %s" % STORAGEDIR
storage = Folder(STORAGEDIR)
storage.mkdir()
storage.chown('www-data')

# -----------------------------------------------------------------------------

virtualenv = VirtualEnv(DIR + "/python-env")
created = virtualenv.create(
    args.overwrite_virtualenv, args.keep_virtualenv, install_log.filename
)
if created:
    print "Running setup.py"
    virtualenv.run(install_log.filename, "python " + DIR + "/setup.py develop")
    virtualenv.add_moxlib_pointer(MOXDIR)

# -----------------------------------------------------------------------------

# Install WSGI service
print "Setting up oio_rest WSGI service for Apache"
wsgi = WSGI(
    "%s/server-setup/oio_rest.wsgi" % DIR,
    "%s/server-setup/oio_rest.conf" % DIR
)
wsgi.install(False)
