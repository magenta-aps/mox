# -*- coding: utf-8 -*-
from collections import OrderedDict

class SemaWiConverter(object):
    objecttype = ""
    map = {}

    def __init__(self, entity):
        self.entity = entity

    def converted(self):
        return "{{%s\n}}" % "\n|".join(
            [self.objecttype] + ["%s=%s" % (item[0], item[1]) for item in self.map.items()]
        )


class ItSystemConverter(SemaWiConverter):
    objecttype = "System"



    def __init__(self, itsystem):
        super(ItSystemConverter, self).__init__(itsystem)

        self.map = {
            u'Navn': itsystem.current.itsystemnavn,
            u'Nummer': itsystem.id,
            u'Status': '',
            u'Ejer': itsystem.current.tilhoerer,
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
        super(BrugerConverter, self).__init__(bruger)
        self.map = {
            u'Navn': bruger.brugervendtnoegle,
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

