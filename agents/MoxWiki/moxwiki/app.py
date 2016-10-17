# -*- coding: utf-8 -*-
import os

from agent.amqp import MessageListener
from SeMaWi import Semawi
from PyLoRA import Lora

DIR = os.path.dirname(os.path.realpath(__file__))

from templates import ItSystemConverter

# config = read_properties_file("/srv/mox/mox.conf")

class MoxWiki(MessageListener):

    def __init__(self):

        https = False
        address = 'semawi.magenta.dk'
        # consumer_token='my_consumer_token',
        # consumer_secret='my_consumer_secret',
        # access_token='my_access_token',
        # access_secret='my_access_secret'
        username='SeMaWi'
        password='SeMaWiSeMaWi'

        self.semawi = Semawi(address, username, password, https=False)
        self.lora = Lora('https://moxtest.magenta-aps.dk')

        for itsystem in self.lora.itsystemer:
            pagename = itsystem.brugervendtnoegle
            pagetext = unicode(ItSystemConverter(itsystem))
            print pagetext
            page = self.semawi.site.Pages[pagename]
            page.save(pagetext, summary="imported from LoRA instance %s" % self.lora.host)

    def callback(self, channel, method, properties, body):
        print "got message %s" % unicode(body)

main = MoxWiki()
