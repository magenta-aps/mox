# -*- coding: utf-8 -*-
import os
from urlparse import urlparse

from agent.amqpclient import MessageListener
from agent.config import read_properties_files, MissingConfigKeyError
from SeMaWi import Semawi
from PyLoRA import Lora
from PyOIO.OIOCommon.exceptions import InvalidOIOException

DIR = os.path.dirname(os.path.realpath(__file__))

from templates import ItSystemConverter, BrugerConverter

config = read_properties_files("/srv/mox/mox.conf", "settings.conf")

class MoxWiki(MessageListener):

    def __init__(self):

        try:
            wiki_host = config['moxwiki.wiki.host']
            wiki_username = config['moxwiki.wiki.username']
            wiki_password = config['moxwiki.wiki.password']

            amqp_host = config['moxwiki.amqp.host']
            amqp_username = config['moxwiki.amqp.username']
            amqp_password = config['moxwiki.amqp.password']
            amqp_queue = config['moxwiki.amqp.queue']

            rest_host = config['moxwiki.rest.host']
            rest_username = config['moxwiki.rest.username']
            rest_password = config['moxwiki.rest.password']
        except KeyError as e:
            raise MissingConfigKeyError(str(e))

        parsed_amqp_host = urlparse(amqp_host)

        super(MoxWiki, self).__init__(amqp_username, amqp_password, parsed_amqp_host.netloc, amqp_queue, queue_parameters={'durable': True})

        self.semawi = Semawi(wiki_host, wiki_username, wiki_password)
        self.lora = Lora(rest_host, rest_username, rest_password)

        # for itsystem in self.lora.itsystemer:
        #     self.update('ItSystem', itsystem.id, True)
        # for user in self.lora.brugere:
        #     self.update('Bruger', user.id, True)
        self.run()

    convertermap = {
        'Itsystem': ItSystemConverter,
        'Bruger': BrugerConverter
    }

    def callback(self, channel, method, properties, body):
        headers = properties.headers
        messagetype = headers.get("beskedtype")

        if messagetype is not None:
            objecttype = headers.get("objekttype")
            lifycyclecode = headers.get("livscykluskode")
            objectid = headers.get("objektID")
            messagetype = messagetype.lower()
            if messagetype == 'notification':
                try:
                    if lifycyclecode == 'Slettet':
                        self.delete(objecttype, objectid)
                    else:
                        self.update(objecttype, objectid)
                except InvalidOIOException as e:
                    print e

    def update(self, objecttype, objectid, accept_cached=False):
        instance = self.lora.get_object(objecttype, objectid, not accept_cached)
        converter = self.convertermap[objecttype]
        pagename = instance.brugervendtnoegle
        pagetext = unicode(converter(instance))
        page = self.semawi.site.Pages[pagename]
        page.save(pagetext, summary="Imported from LoRA instance %s" % self.lora.host)

    def delete(self, objecttype, objectid):
        instance = self.lora.get_object(objecttype, objectid)
        pagename = instance.brugervendtnoegle
        page = self.semawi.site.Pages[pagename]
        page.delete(reason="Deleted in LoRa instance %s" % self.lora.host)


main = MoxWiki()
