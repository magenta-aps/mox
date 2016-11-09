#!/usr/bin/python
# -*- coding: utf-8 -*-
import os

from agent.amqpclient import MessageListener
from agent.message import NotificationMessage
from agent.config import read_properties_files, MissingConfigKeyError
from SeMaWi import Semawi
from PyLoRA import Lora
from PyOIO.OIOCommon.exceptions import InvalidOIOException
from PyOIO.organisation import Bruger, ItSystem

from jinja2 import Environment, PackageLoader
from moxwiki.jinja2_override.silentundefined import SilentUndefined

from moxwiki.exceptions import TemplateNotFoundException

DIR = os.path.dirname(os.path.realpath(__file__))

configfile = DIR + "/settings.conf"
config = read_properties_files("/srv/mox/mox.conf", configfile)
template_environment = Environment(loader=PackageLoader('moxwiki', 'templates'), undefined=SilentUndefined)

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

        # super(MoxWiki, self).__init__(amqp_username, amqp_password, amqp_host, amqp_queue, queue_parameters={'durable': True})

        self.semawi = Semawi(wiki_host, wiki_username, wiki_password)
        self.lora = Lora(rest_host, rest_username, rest_password)

        self.accepted_object_types = ['bruger', 'interessefaellesskab', 'itsystem', 'organisation', 'organisationenhed', 'organisationfunktion']


    def test(self):
        self.lora.load_all_of_type(ItSystem)
        # print self.lora.all_items['1706778e-30ff-410a-ad31-a9bb14c6c2b5'].json
        self.update('Itsystem', '1706778e-30ff-410a-ad31-a9bb14c6c2b5', True)

    def callback(self, channel, method, properties, body):
        message = NotificationMessage.parse(properties.headers, body)
        if message:
            print "Got a notification"
            if message.objecttype in self.accepted_object_types:
                print "Object type '%s' accepted" % message.objecttype
                try:
                    if message.lifecyclecode == 'Slettet':
                        print "lifecyclecode is '%s', performing delete" % message.lifecyclecode
                        self.delete(message.objecttype, message.objectid)
                    else:
                        print "lifecyclecode is '%s', performing update" % message.lifecyclecode
                        self.update(message.objecttype, message.objectid)
                except InvalidOIOException as e:
                    print e
            else:
                print "Object type '%s' rejected" % message.objecttype

    def update(self, objecttype, objectid, accept_cached=False):
        instance = self.lora.get_object(objectid, objecttype, not accept_cached)
        title = instance.current.brugervendtnoegle
        pagename = "%s_%s" % (title, objectid)

        page = self.semawi.site.Pages[pagename]

        if not page.exists:
            previous_registrering = instance.current.before
            if previous_registrering:
                old_title = previous_registrering.brugervendtnoegle
                old_pagename = "%s_%s" % (old_title, objectid)
                old_page = self.semawi.site.Pages[old_pagename]
                if old_page.exists:
                    print "Moving wiki page %s to %s" % (old_pagename, pagename)
                    old_page.move(pagename, reason="LoRa object %s has changed name from %s to %s" % (objectid, old_title, title))

        template = template_environment.get_template("%s.txt" % objecttype)
        if template is None:
            raise TemplateNotFoundException("%s.txt" % objecttype)

        pagetext = template.render({'object': instance, 'begin': '{{', 'end': '}}'})
        print pagetext

        # if pagetext != page.text():
        #    page.save(pagetext, summary="Imported from LoRA instance %s" % self.lora.host)

    def delete(self, objecttype, objectid):
        instance = self.lora.get_object(objectid, objecttype)
        pagename = "%s_%s" % (instance.current.brugervendtnoegle, objectid)
        #page = self.semawi.site.Pages[pagename]
        #page.delete(reason="Deleted in LoRa instance %s" % self.lora.host)


main = MoxWiki()
main.test()