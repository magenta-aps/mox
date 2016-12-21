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
}

parser = argparse.ArgumentParser(description='Install MoxDocumentDownload')

parser.add_argument('--rest-host', action='store')

args = parser.parse_args()

# ------------------------------------------------------------------------------

configfile = DIR + "/moxdocumentdownload/moxdocumentdownload.conf"

config_map = [
    ('rest_host', 'moxdocumentdownload.rest.host'),
]
config = Config(configfile)

config.prompt(config_map, args, defaults)

config.save()
