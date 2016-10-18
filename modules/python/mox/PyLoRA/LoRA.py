#!/usr/bin/env python

import requests
import json
from uuid import UUID
from PyOIO.organisation import Bruger, ItSystem
from PyOIO.OIOCommon.exceptions import InvalidUUIDException, InvalidObjectTypeException, TokenException

class Lora(object):
    """A Lora object represents a single running instance of the LoRa service.
    """
    objecttypes = {'Itsystem': ItSystem, 'Bruger': Bruger}
    itsystemer = []
    brugere = []
    items = {}

    def __init__(self, host, username, password):
        """ Args:
        host:   string - the hostname of the LoRa instance
        """
        self.host = host

        self.token = self.get_token(username, password)
        self._populate_org_brugere()
        self._populate_org_systemer()
        self.items = {}

    def get_token(self, username, password):
        response = requests.post(
            self.host + "/get-token",
            data={
                'username': username,
                'password': password,
                'sts': self.host + ":9443/services/wso2carbon-sts?wsdl"
            }
        )
        if not response.text.startswith("saml-gzipped"):
            try:
                errormessage = json.loads(response.text)['message']
            except ValueError:
                errormessage = response.text
            raise TokenException(errormessage)

        return response.text

    def _populate_org_systemer(self):
        """creates the objects from /organisation/itsystem?search
        """
        self.itsystemer = []
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
            system = ItSystem(self.host, guid, self.token)
            self.itsystemer.append(system)
            self.items[guid] = system

    def _populate_org_brugere(self):
        """creates the objects from /organisation/bruger?search

        """
        self.brugere = []
        url = self.host + '/organisation/bruger?search'
        response = requests.get(
            url,
            headers={
                'authorization': self.token
            }
        )
        data = json.loads(response.text)
        guids = data['results'][0]
        for guid in guids:
            user = Bruger(self.host, guid, self.token)
            self.brugere.append(user)
            self.items[guid] = user

    def __repr__(self):
        return 'Lora("%s")' % (self.host)

    def __str__(self):
        return 'Lora: %s' % (self.host)

    def get_object(self, objecttype, uuid, force_refresh=False):
        try:
            UUID(uuid)
        except ValueError:
            raise InvalidUUIDException(uuid)
        if objecttype not in self.objecttypes:
            raise InvalidObjectTypeException(objecttype)

        if uuid in self.items and not force_refresh:
            return self.items[uuid]
        else:
            item = self.objecttypes[objecttype](self.host, uuid, self.token)
            if force_refresh:
                self.items[uuid] = item
            return item
