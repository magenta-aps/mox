#!/usr/bin/python

import argparse
import os
import sys
import subprocess
from socket import gethostname
from installutils import Config, VirtualEnv

domain = gethostname()
DIR = os.path.dirname(os.path.realpath(sys.argv[0]))
MOXDIR = os.path.abspath(DIR + "/../..")
MODULES_DIR = os.path.abspath(MOXDIR + "/modules/python")

parser = argparse.ArgumentParser(description='Install MoxWiki')

parser.add_argument('-y', '--overwrite-virtualenv', action='store_true')
parser.add_argument('-n', '--keep-virtualenv', action='store_true')

parser.add_argument('--wiki-host', action='store', default="http://%s" % domain)
parser.add_argument('--wiki-user', action='store', default='SeMaWi')
parser.add_argument('--wiki-pass', action='store', default='SeMaWiSeMaWi')

parser.add_argument('--amqp-host', action='store', default='http://moxtest.magenta-aps.dk')
parser.add_argument('--amqp-user', action='store', default='guest')
parser.add_argument('--amqp-pass', action='store', default='guest')
parser.add_argument('--amqp-queue', action='store', default='notifications')

parser.add_argument('--rest-host', action='store', default="http://%s" % domain)
parser.add_argument('--rest-user', action='store', default='admin')
parser.add_argument('--rest-pass', action='store', default='admin')

args = parser.parse_args()

# ------------------------------------------------------------------------------

virtualenv = VirtualEnv(DIR + "/python-env")
created = virtualenv.create(args.overwrite_virtualenv, args.keep_virtualenv)
if created:
    subprocess.call(['ln', '--symbolic', '--force', MODULES_DIR + "/mox", virtualenv.environment_dir + "/local/mox"])
    virtualenv.run("python " + DIR + "/setup.py develop")

# ------------------------------------------------------------------------------

configfile = DIR + "/moxwiki/settings.conf"

config_map = {
    'wiki_host': 'moxwiki.wiki.host',
    'wiki_user': 'moxwiki.wiki.username',
    'wiki_pass': 'moxwiki.wiki.password',
    'amqp_host': 'moxwiki.amqp.host',
    'amqp_user': 'moxwiki.amqp.username',
    'amqp_pass': 'moxwiki.amqp.password',
    'amqp_queue': 'moxwiki.amqp.queue',
    'rest_host': 'moxwiki.rest.host',
    'rest_user': 'moxwiki.rest.username',
    'rest_pass': 'moxwiki.rest.password'
}
config = Config(configfile)

for key in config_map:
    if hasattr(args, key):
        config.set(config_map[key], getattr(args, key))

config.save()