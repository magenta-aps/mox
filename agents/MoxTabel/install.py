#!/usr/bin/python

import argparse
import os
import sys
from installutils import VirtualEnv, create_user, run, sudo

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))

parser = argparse.ArgumentParser(description='Install MoxTabel')

parser.add_argument('-C', '--skip-compile', action='store_true')

args = parser.parse_args()

# ------------------------------------------------------------------------------

if not args.skip_compile:
    print 'Building Maven package'

    run('mvn', 'package', '-Dmaven.test.skip=true')

# ------------------------------------------------------------------------------

print 'Installing service'

create_user('moxtabel')

sudo('touch', '/var/log/mox/moxtabel.log')
sudo('chown', 'moxtabel:mox', '/var/log/mox/moxtabel.log')

venv = VirtualEnv(DIR + "/python-env")
venv.expand_template('setup/moxtabel.conf.in')

sudo('install', '-m', '644', 'setup/moxtabel.conf', '/etc/init/moxtabel.conf')
sudo('service', 'moxtabel', 'restart')
