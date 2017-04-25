#!/usr/bin/python

import argparse
import os
import sys
from installutils import Service, LogFile, VirtualEnv, expand_template, run

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))

parser = argparse.ArgumentParser(description='Install Python agents')
args = parser.parse_args()

# ------------------------------------------------------------------------------


print 'Installing mox_advis service'

LogFile('/var/log/mox/mox-advis.log', 'moxlog').create()
VirtualEnv().expand_template('setup/mox_advis.sh.in', mode=755)
os.chmod(os.path.join(DIR, 'setup/mox_advis.sh'), 0755)
service = Service('setup/mox_advis.sh', user='moxlog',
                  after=('rabbitmq-server.service'))
service.install()

print 'Installing mox_elk_log service'
LogFile('/var/log/mox/mox-elk.log', 'moxlog').create()
VirtualEnv().expand_template('setup/mox_elk_log.sh.in')
os.chmod(os.path.join(DIR, 'setup/mox_elk_log.sh'), 0755)
service = Service('setup/mox_elk_log.sh', user='moxlog',
                  after=('rabbitmq-server.service'))
service.install()
