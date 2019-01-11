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
import socket
from installutils import Config

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))

domain = socket.getfqdn(socket.gethostname())
defaults = {
    'rest_host': "https://%s" % domain,
    'amqp_host': domain,
    'amqp_exchange': 'mox.documentconvert',
    'amqp_user': 'guest',
    'amqp_pass': 'guest'
}

parser = argparse.ArgumentParser(description='Install MoxDocumentUpload')

parser.add_argument('--amqp-host', action='store')
parser.add_argument('--amqp-exchange', action='store')
parser.add_argument('--amqp-user', action='store')
parser.add_argument('--amqp-pass', action='store')
parser.add_argument('--rest-host', action='store')

args = parser.parse_args()

# ------------------------------------------------------------------------------

configfile = DIR + "/moxdocumentupload/moxdocumentupload.conf"

config_map = [
    ('amqp_host', 'moxdocumentupload.amqp.host'),
    ('amqp_exchange', 'moxdocumentupload.amqp.exchange'),
    ('amqp_user', 'moxdocumentupload.amqp.username'),
    ('amqp_pass', 'moxdocumentupload.amqp.password'),
    ('rest_host', 'moxdocumentupload.rest.host'),
]
config = Config(configfile)

config.prompt(config_map, args, defaults)

config.save()
