#!/usr/bin/env python

import requests
import json
from PyOIO.organisation import Bruger, ItSystem

class Lora(object):
    """A Lora object represents a single running instance of the LoRa service.
    """

    def __init__(self, host):
        """ Args:
        host:   string - the hostname of the LoRa instance
        """
        self.host = host

        self.token = self.get_token('admin', 'admin')
        self.brugere = self._populate_org_brugere()
        self.itsystemer = self._populate_org_systemer()

    def get_token(self, username, password):
        response = requests.post(
            self.host + "/get-token",
            data={
                'username': username,
                'password': password,
                'sts': self.host + ":9443/services/wso2carbon-sts?wsdl"
            }
        )
        return response.text

    def _populate_org_systemer(self):
        """creates the objects from /organisation/itsystem?search
        """
        systemer = []
        url = self.host + '/organisation/itsystem?search'
        response = requests.get(
            url,
            headers={
                'authorization': self.token
            }
        )
        data = json.loads(response.text)
        guids = data['results'][0]
        for guid in guids:
            systemer.append(ItSystem(self.host, guid, self.token))
        return systemer

    def _populate_org_brugere(self):
        """creates the objects from /organisation/bruger?search

        """
        brugere = []
        url = self.host + '/organisation/bruger?search'
        response = requests.get(
            url,
            headers={
                'authorization': self.token
            }
        )
        data = json.loads(response.text)
        print data
        guids = data['results'][0]
        for guid in guids:
            brugere.append(Bruger(self.host, guid, self.token))
        return brugere

    def __repr__(self):
        return 'Lora("%s")' % (self.host)

    def __str__(self):
        return 'Lora: %s' % (self.host)
