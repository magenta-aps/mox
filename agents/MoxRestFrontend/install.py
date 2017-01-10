#!/usr/bin/python

import argparse
import os
import sys
from installutils import VirtualEnv, create_user, run, sudo

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))

parser = argparse.ArgumentParser(description='Install MoxRestFrontend')

parser.add_argument('-C', '--skip-compile', action='store_true')

args = parser.parse_args()

# ------------------------------------------------------------------------------

if not args.skip_compile:
    print 'Building Maven package'

    run('mvn', 'package', '-Dmaven.test.skip=true')

# ------------------------------------------------------------------------------

print 'Installing service'

create_user('moxrestfrontend')

sudo('touch', '/var/log/mox/moxrestfrontend.log')
sudo('chown', 'moxrestfrontend:mox', '/var/log/mox/moxrestfrontend.log')

venv = VirtualEnv(os.path.join(DIR, '..', 'MoxDocumentUpload', 'python-env'))
venv.expand_template('setup/moxrestfrontend.conf.in')

sudo('install', '-m', '644', 'setup/moxrestfrontend.conf',
     '/etc/init/moxrestfrontend.conf')
sudo('service', 'moxrestfrontend', 'restart')
