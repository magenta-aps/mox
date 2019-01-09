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
