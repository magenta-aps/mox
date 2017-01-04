#!/usr/bin/python

import argparse
import os
import sys
from installutils import VirtualEnv, WSGI, sudo

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))

parser = argparse.ArgumentParser(description='Install OIO REST')

parser.add_argument('-y', '--overwrite-virtualenv', action='store_true')
parser.add_argument('-n', '--keep-virtualenv', action='store_true')
parser.add_argument('-s', '--skip-system-deps', action='store_true')

args = parser.parse_args()

# ------------------------------------------------------------------------------

if not args.skip_system_deps:
    print "Installing system dependancies"

    with open(os.path.join(DIR, 'SYSTEM_DEPENDENCIES')) as fp:
        deps = fp.read().strip().splitlines()

    sudo('apt-get', '-y', 'install', *deps)

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

# ------------------------------------------------------------------------------

# Install WSGI service
print "Setting up OIO REST WSGI service for Apache"
wsgi = WSGI(
    "server-setup/oio_rest.wsgi.in",
    "server-setup/oio_rest.conf.in",
    virtualenv,
)
wsgi.install(True)
