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
