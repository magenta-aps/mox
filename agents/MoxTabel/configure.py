#!/usr/bin/python

import argparse
import os
import sys
import socket
from installutils import Config

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))

domain = socket.getfqdn(socket.gethostname())
defaults = {
    'rest_host': "https://%s" % domain,
    'amqp_incoming_host': domain,
    'amqp_incoming_exchange': 'mox.documentconvert',
    'amqp_incoming_user': 'guest',
    'amqp_incoming_pass': 'guest',
    'amqp_outgoing_host': domain,
    'amqp_outgoing_exchange': 'mox.rest',
    'amqp_outgoing_user': 'guest',
    'amqp_outgoing_pass': 'guest'
}

parser = argparse.ArgumentParser(description='Install MoxDocumentUpload')

parser.add_argument('--amqp-incoming-host', action='store')
parser.add_argument('--amqp-incoming-exchange', action='store')
parser.add_argument('--amqp-incoming-user', action='store')
parser.add_argument('--amqp-incoming-pass', action='store')
parser.add_argument('--amqp-outgoing-host', action='store')
parser.add_argument('--amqp-outgoing-exchange', action='store')
parser.add_argument('--amqp-outgoing-user', action='store')
parser.add_argument('--amqp-outgoing-pass', action='store')
parser.add_argument('--rest-host', action='store')

args = parser.parse_args()

# ------------------------------------------------------------------------------

configfile = DIR + "/moxtabel.conf"

config_map = [
    ('amqp_incoming_host', 'moxtabel.amqp.incoming.host'),
    ('amqp_incoming_exchange', 'moxtabel.amqp.incoming.exchange'),
    ('amqp_incoming_user', 'moxtabel.amqp.incoming.username'),
    ('amqp_incoming_pass', 'moxtabel.amqp.incoming.password'),
    ('amqp_outgoing_host', 'moxtabel.amqp.outgoing.host'),
    ('amqp_outgoing_exchange', 'moxtabel.amqp.outgoing.exchange'),
    ('amqp_outgoing_user', 'moxtabel.amqp.outgoing.username'),
    ('amqp_outgoing_pass', 'moxtabel.amqp.outgoing.password'),
    ('rest_host', 'moxtabel.rest.host'),
]
config = Config(configfile)

config.prompt(config_map, args, defaults)

config.save()
