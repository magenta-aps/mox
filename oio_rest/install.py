#!/usr/bin/python

import argparse
import datetime
import os
import subprocess
import sys
from installutils import VirtualEnv, WSGI

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))

parser = argparse.ArgumentParser(description='Install OIO REST')

parser.add_argument('-y', '--overwrite-virtualenv', action='store_true')
parser.add_argument('-n', '--keep-virtualenv', action='store_true')
parser.add_argument('-s', '--skip-system-deps', action='store_true')

args = parser.parse_args()

# ------------------------------------------------------------------------------

logfilename = "%s/install.log" % DIR

def sudo(*args):
    with open(logfilename, 'a') as logfp:
        logfp.write('\n{}\nSUDO: {}\n\n'.format(datetime.datetime.now(),
                                                ' '.join(args)))
        logfp.flush()

        subprocess.check_call(('sudo',) + args, stdout=logfp, stderr=logfp)

if not args.skip_system_deps:
    with open(os.path.join(DIR, 'SYSTEM_DEPENDENCIES')) as fp:
        deps = fp.read().strip().splitlines()

    sudo('apt-get', '-y', 'install', *deps)

sudo('install', '-d', '-o', 'mox', '-g', 'mox',
     '/var/mox', '/var/log/mox', '/var/log/mox/oio_rest')

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
print "Setting up moxdocumentdownload WSGI service for Apache"
wsgi = WSGI(
    "server-setup/oio_rest.wsgi.in",
    "server-setup/oio_rest.conf.in",
    virtualenv,
)
wsgi.install(True)
