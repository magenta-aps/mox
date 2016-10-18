# -*- coding: utf-8 -*-
from collections import OrderedDict

class SemaWiConverter(object):
    converted = {}
    objecttype = ""

    def __unicode__(self):
        return "{{%s\n}}" % "\n|".join(
            [self.objecttype] + ["%s=%s" % (item[0], item[1]) for item in self.converted.items()]
        )


class ItSystemConverter(SemaWiConverter):
    objecttype = "System"

    def __init__(self, itsystem):
        self.converted = {
            u'Navn': itsystem.navn,
            u'Nummer': itsystem.id,
            u'Status': '',
            u'Ejer': '',
            u'Administrator': '',
            u'Budgetansvarlig': '',
            u'Målgruppe': '',
            u'MålgruppeOE': '',
            u'Leverandør': '',
            u'Driftsleverandør': '',
            u'Driftsplacering': '',
            u'PersonfølsomInfo': '',
            u'AnmeldtDatatilsynet': '',
            u'PersonfølsomType': '',
            u'Afhængigheder': '',
            u'IDMVenligt': '',
            u'Dokumentation': '',
            u'KLE': '',
            u'URL': '',
            u'Geodata': '',
            u'SystemImplementsPrinciples': '',
            u'AarligeOmkostninger': ''
        }


class BrugerConverter(SemaWiConverter):
    objecttype = "Bruger"

    def __init__(self, bruger):
        self.converted = {
            u'Navn': bruger.navn,
            u'Nummer': bruger.id,
            u'Status': '',
            u'Ejer': '',
            u'Administrator': '',
            u'Budgetansvarlig': '',
            u'Målgruppe': '',
            u'MålgruppeOE': '',
            u'Leverandør': '',
            u'Driftsleverandør': '',
            u'Driftsplacering': '',
            u'PersonfølsomInfo': '',
            u'AnmeldtDatatilsynet': '',
            u'PersonfølsomType': '',
            u'Afhængigheder': '',
            u'IDMVenligt': '',
            u'Dokumentation': '',
            u'KLE': '',
            u'URL': '',
            u'Geodata': '',
            u'SystemImplementsPrinciples': '',
            u'AarligeOmkostninger': ''
        }

