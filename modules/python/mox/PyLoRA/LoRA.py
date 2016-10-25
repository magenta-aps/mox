#!/usr/bin/env python

import requests
import json
from uuid import UUID
from PyOIO.organisation import Bruger, Interessefaellesskab, ItSystem, Organisation, OrganisationEnhed, OrganisationFunktion
from PyOIO.OIOCommon.exceptions import InvalidUUIDException, InvalidObjectTypeException, TokenException, ItemNotFoundException

class Lora(object):
    """A Lora object represents a single running instance of the LoRa service.
    """
    objecttypes = [
        Bruger,
        Interessefaellesskab,
        ItSystem,
        Organisation,
        OrganisationEnhed,
        OrganisationFunktion
    ]

    def __init__(self, host, username, password):
        """ Args:
        host:   string - the hostname of the LoRa instance
        """
        self.host = host

        self.token = self.get_token(username, password)
        self.object_map = {
            cls.ENTITY_CLASS: cls for cls in self.objecttypes
        }
        self.all_items = {}
        self.items_by_class = {
            key: {} for key in self.object_map.keys()
        }

        # self.load_type(Bruger.ENTITY_CLASS)
        self.load_type(ItSystem.ENTITY_CLASS)

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

    def get_headers(self):
        return {'authorization': self.token}

    def load_type(self, objecttype):
        objectclass = self.object_map[objecttype]
        url = self.host + objectclass.basepath() + "?search"
        response = requests.get(url, headers=self.get_headers())
        data = json.loads(response.text)
        guids = data['results'][0]
        for guid in guids:
            self.get_object(guid, objecttype, True, True)

    @property
    def itsystemer(self):
        return self.items_by_class[ItSystem.ENTITY_CLASS]

    @property
    def brugere(self):
        return self.items_by_class[ItSystem.ENTITY_CLASS]

    def __repr__(self):
        return 'Lora("%s")' % (self.host)

    def __str__(self):
        return 'Lora: %s' % (self.host)

    def get_object(self, uuid, objecttype=None, force_refresh=False, refresh_cache=True):
        try:
            UUID(uuid)
        except ValueError:
            raise InvalidUUIDException(uuid)

        if uuid in self.all_items and not force_refresh:
            return self.all_items[uuid]

        if objecttype is None:
            objecttype = self.object_map.keys()
        elif type(objecttype) != list:
            objecttype = [objecttype]

        for otype in objecttype:
            if otype not in self.object_map.keys():
                raise InvalidObjectTypeException(otype)

            item = self.object_map[otype](self, uuid)
            try:
                item.load()
            except ItemNotFoundException:
                print "It's not a %s" % otype
                continue

            if refresh_cache:
                self.all_items[uuid] = item
                self.items_by_class[otype][uuid] = item
            return item
