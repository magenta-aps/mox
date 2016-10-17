#!/usr/bin/env python
# coding=utf-8

import mwclient


class Semawi(object):

    def __init__(self, host, username, password, https=True):
        self.host = host
        self.site = mwclient.Site(
            ('https' if https else 'http', self.host),
            path='/'
        )
        self.username = username
        self.password = password
        self.site.login(self.username, self.password)

    def pull_lora_org_sys(self, lora):
        """Super ugly, totally hardwired, just for PoC
        """
        pages = []
        systempl = u"""
{{System
|Navn=%s
|Nummer=%s
|Status=%s
|Ejer=%s
|Administrator=%s
|Budgetansvarlig=%s
|Målgruppe=%s
|MålgruppeOE=%s
|Leverandør=%s
|Driftsleverandør=%s
|Driftsplacering=%s
|PersonfølsomInfo=%s
|AnmeldtDatatilsynet=%s
|PersonfølsomType=%s
|Afhængigheder=%s
|IDMVenligt=%s
|Dokumentation=%s
|KLE=%s
|URL=%s
|Geodata=%s
|SystemImplementsPrinciples=%s
|AarligeOmkostninger=%s
}}
        """
        for itsystem in lora.itsystemer:
            pagename = itsystem.brugervendtnoegle
            pagetext = systempl % (itsystem.navn, '', '', '', '', '',
                                   '', '', '', '', '', '', '', '', '', '', '', '',
                                   '', '', '', '')
            print pagetext
            page = self.site.Pages[pagename]
            page.save(pagetext, summary="imported from LoRA instance %s" % lora.host)

    def __repr__(self):
        return "SeMaWi(%s)" % self.host

    def __str__(self):
        return "SeMaWi(%s)" % self.host
