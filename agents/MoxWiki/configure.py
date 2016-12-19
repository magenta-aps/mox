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
    'rest_host': "https://%s" % domain,
    'wiki_host': "https://%s" % domain
}

parser = argparse.ArgumentParser(description='Install MoxWiki')

parser.add_argument('--wiki-host', action='store')
parser.add_argument('--wiki-user', action='store')
parser.add_argument('--wiki-pass', action='store')

parser.add_argument('--amqp-host', action='store')
parser.add_argument('--amqp-user', action='store')
parser.add_argument('--amqp-pass', action='store')
parser.add_argument('--amqp-exchange', action='store')

parser.add_argument('--rest-host', action='store')
parser.add_argument('--rest-user', action='store')
parser.add_argument('--rest-pass', action='store')

args = parser.parse_args()

configfile = DIR + "/moxwiki/settings.conf"

config_map = [
    ('wiki_host', 'moxwiki.wiki.host'),
    ('wiki_user', 'moxwiki.wiki.username'),
    ('wiki_pass', 'moxwiki.wiki.password'),
    ('amqp_host', 'moxwiki.amqp.host'),
    ('amqp_user', 'moxwiki.amqp.username'),
    ('amqp_pass', 'moxwiki.amqp.password'),
    ('amqp_exchange', 'moxwiki.amqp.exchange'),
    ('rest_host', 'moxwiki.rest.host'),
    ('rest_user', 'moxwiki.rest.username'),
    ('rest_pass', 'moxwiki.rest.password')
]
config = Config(configfile)

config.prompt(config_map, args, defaults)

config.save()
