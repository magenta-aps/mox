#!/usr/bin/python

import argparse
import os
import sys
from installutils import LogFile, Service, run

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))

parser = argparse.ArgumentParser(description='Install MoxRestFrontend')

parser.add_argument('-C', '--skip-compile', action='store_true')

args = parser.parse_args()

# ------------------------------------------------------------------------------

if not args.skip_compile:
    print 'Building Maven package'

    run('mvn', 'package', '-Dmaven.test.skip=true', '-Dmaven.clean.skip=true')

# ------------------------------------------------------------------------------

print 'Installing service'

LogFile('/var/log/mox/moxrestfrontend.log', 'moxrestfrontend').create()

service = Service('moxrestfrontend.sh', user='moxrestfrontend',
                  after=('rabbitmq-server.service'))
service.install()
