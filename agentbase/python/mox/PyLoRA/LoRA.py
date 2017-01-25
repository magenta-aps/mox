#!/usr/bin/env python

import requests
import json
from uuid import UUID
from PyOIO.OIOCommon.entity import OIOEntity
from PyOIO.organisation import Bruger, Interessefaellesskab, ItSystem
from PyOIO.organisation Organisation, OrganisationEnhed, OrganisationFunktion
from PyOIO.klassifikation import Facet, Klasse, Klassifikation
from PyOIO.OIOCommon.exceptions import InvalidUUIDException
from PyOIO.OIOCommon.exceptions import InvalidObjectTypeException
from PyOIO.OIOCommon.exceptions import TokenException
from PyOIO.OIOCommon.exceptions import ItemNotFoundException
from PyOIO.OIOCommon.exceptions import RestAccessException
import pylru
import urllib


class Lora(object):
    """A Lora object represents a single running instance of the LoRa service.
    """
    objecttypes = [
        Bruger,
        Interessefaellesskab,
        ItSystem,
        Organisation,
        OrganisationEnhed,
        OrganisationFunktion,
        Facet,
        Klasse,
        Klassifikation
    ]

    def __init__(self, host, username, password):
        """ Args:
        host:   string - the hostname of the LoRa instance
        username:   string - the username to authenticate as
        password:   string - the corresponding password
        """
        self.host = host

        self.username = username
        self.password = password
        self.obtain_token()
        self.object_map = {
            cls.ENTITY_CLASS: cls for cls in self.objecttypes
        }
        self.all_items = pylru.lrucache(10000)

    def __repr__(self):
        return 'Lora("%s")' % (self.host)

    def __str__(self):
        return 'Lora: %s' % (self.host)

    def obtain_token(self):
        response = requests.post(
            self.host + "/get-token",
            data={
                'username': self.username,
                'password': self.password,
                'sts': self.host + ":9443/services/wso2carbon-sts?wsdl"
            }
        )
        if not response.text.startswith("saml-gzipped"):
            try:
                errormessage = json.loads(response.text)['message']
            except ValueError:
                errormessage = response.text
            raise TokenException(errormessage)
        self.token = response.text

    def get_headers(self):
        return {'authorization': self.token}

    def request(self, url, method='GET', **kwargs):
        method = method.upper()
        if 'headers' not in kwargs:
            kwargs['headers'] = {}
        kwargs['headers'].update(self.get_headers())
        response = requests.request(method, url, **kwargs)
        if response.status_code == 401:
            # Token may be expired. Get a new one and try again
            self.obtain_token()
            kwargs['headers'].update(self.get_headers())
            response = requests.request(method, url, **kwargs)
            if response.status_code == 401:
                # Failed with a new token. Bail
                raise RestAccessException(response.text)
        return response

    def get_uuids_of_type(self, objecttype, since=None):
        if issubclass(objecttype, OIOEntity):
            objecttype = objecttype.ENTITY_CLASS
        objectclass = self.object_map[objecttype]
        url = self.host + objectclass.basepath + "?search"
        if since:
            url += '&registreringfra=%s' % urllib.quote_plus(
                since.strftime('%Y-%m-%d %H:%M:%S%z')
            )
        response = self.request(url, headers=self.get_headers())
        data = json.loads(response.text)
        return data['results'][0]

    def load_all_of_type(self, objecttype):
        if issubclass(objecttype, OIOEntity):
            objecttype = objecttype.ENTITY_CLASS
        for guid in self.get_uuids_of_type(objecttype):
            self.get_object(guid, objecttype, True, True)

    def get_object(self, uuid, objecttype=None,
                   force_refresh=False, refresh_cache=True):
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
                # print "It's not a %s" % otype
                continue

            if refresh_cache:
                self.all_items[uuid] = item
            return item
