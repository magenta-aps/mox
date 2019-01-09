# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


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
