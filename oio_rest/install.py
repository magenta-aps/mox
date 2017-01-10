#!/usr/bin/python

import argparse
import os
import sys
from installutils import VirtualEnv, WSGI, Folder, sudo, install_dependencies

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))
STORAGEDIR = '/var/mox'

parser = argparse.ArgumentParser(description='Install OIO REST')

parser.add_argument('-y', '--overwrite-virtualenv', action='store_true')
parser.add_argument('-n', '--keep-virtualenv', action='store_true')
parser.add_argument('-s', '--skip-system-deps', action='store_true')

args = parser.parse_args()

# ------------------------------------------------------------------------------

if not args.skip_system_deps:
    print "Installing system dependancies"

    install_dependencies("%s/SYSTEM_DEPENDENCIES" % DIR)

sudo('install', '-d', '-o', 'mox', '-g', 'mox',
     '/var/mox', '/var/log/mox', '/var/log/mox/oio_rest')

virtualenv = VirtualEnv(DIR + "/python-env")
created = virtualenv.create(
    args.overwrite_virtualenv, args.keep_virtualenv,
)

if created:
    print "Running setup.py"
    virtualenv.run(DIR + "/setup.py", "develop")
    virtualenv.add_moxlib_pointer()

# -----------------------------------------------------------------------------

# Create the MOX content storage directory and give the www-data user ownership
MOX_STORAGE = "/var/mox"
print "Creating MOX content storage directory %s" % STORAGEDIR
storage = Folder(STORAGEDIR)
storage.mkdir()
storage.chown('www-data')

# ------------------------------------------------------------------------------

# Install WSGI service
print "Setting up OIO REST WSGI service for Apache"
wsgi = WSGI(
    "server-setup/oio_rest.wsgi.in",
    "server-setup/oio_rest.conf.in",
    virtualenv,
)
wsgi.install(True)
