# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


#!/usr/bin/env python
# coding=utf-8

import mwclient
from urlparse import urlparse


class Semawi(object):

    def __init__(self, host, username, password):
        parsed_url = urlparse(host)
        self.host = host

        self.site = mwclient.Site(
            (parsed_url.scheme, parsed_url.netloc),
            path='/'
        )
        self.username = username
        self.password = password
        self.site.login(self.username, self.password)

    def __repr__(self):
        return "SeMaWi(%s)" % self.host

    def __str__(self):
        return "SeMaWi(%s)" % self.host
