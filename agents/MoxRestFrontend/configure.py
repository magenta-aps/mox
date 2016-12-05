#!/usr/bin/python

import argparse
import os
import sys
import socket
from installutils import Config

domain = socket.getfqdn(socket.gethostname())
DIR = os.path.dirname(os.path.realpath(sys.argv[0]))

defaults = {
    'amqp_host': domain,
    'amqp_exchange': 'mox.notifications',
    'rest_host': "https://%s" % domain
}

parser = argparse.ArgumentParser(description='Install MoxRestFrontend')

parser.add_argument('--rest-host', action='store')
parser.add_argument('--amqp-host', action='store')
parser.add_argument('--amqp-user', action='store')
parser.add_argument('--amqp-pass', action='store')
parser.add_argument('--amqp-exchange', action='store')

args = parser.parse_args()

configfile = DIR + "/moxrestfrontend.conf"

config_map = [
    ('amqp_host', 'moxrestfrontend.amqp.host'),
    ('amqp_user', 'moxrestfrontend.amqp.username'),
    ('amqp_pass', 'moxrestfrontend.amqp.password'),
    ('amqp_exchange', 'moxrestfrontend.amqp.exchange'),
    ('rest_host', 'moxrestfrontend.rest.host')
]
config = Config(configfile)

config.prompt(config_map, args, defaults)

config.save()
