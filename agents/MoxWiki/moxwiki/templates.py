# -*- coding: utf-8 -*-
from collections import OrderedDict
from PyOIO.OIOCommon import OIOEntity
from PyOIO.organisation import Bruger, Interessefaellesskab, ItSystem, Organisation, OrganisationEnhed, OrganisationFunktion

class SemaWiConverter(object):
    wiki_type_name = ""
    entity_class = OIOEntity
    map = {}

    def __init__(self, entity):
        if not isinstance(entity, self.entity_class):
            raise IncorrectEntityClassException(entity, self.entity_class)
        self.entity = entity

    def converted(self):
        return "{{%s\n}}" % "\n|".join(
            [self.wiki_type_name] + ["%s=%s" % (item[0], item[1]) for item in self.map.items()]
        )


class IncorrectEntityClassException(Exception):
    def __init__(self, entity, expected_class):
        super(IncorrectEntityClassException, self).__init__("Incorrect class instance submitted for conversion. Expected %s, got %s" % (expected_class.__name__, entity.__class__.__name__))



class BrugerConverter(SemaWiConverter):
    wiki_type_name = "Bruger"
    entity_class = Bruger

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

class ItSystemConverter(SemaWiConverter):
    wiki_type_name = "System"
    entity_class = ItSystem

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


class InteressefaellesskabConverter(SemaWiConverter):
    wiki_type_name = "Interessefaellesskab"
    entity_class = Interessefaellesskab

    def __init__(self, interessefaellesskab):
        super(InteressefaellesskabConverter, self).__init__(interessefaellesskab)

        self.map = {
            u'Navn': interessefaellesskab.current.itsystemnavn,
            u'Nummer': interessefaellesskab.id,
            u'Status': '',
            u'Ejer': interessefaellesskab.current.tilhoerer,
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




class OrganisationConverter(SemaWiConverter):
    wiki_type_name = "Organisation"
    entity_class = Organisation

    def __init__(self, organisation):
        super(OrganisationConverter, self).__init__(organisation)
        self.map = {
            u'Navn': organisation.brugervendtnoegle,
            u'Nummer': organisation.id,
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

class OrganisationEnhedConverter(SemaWiConverter):
    wiki_type_name = "OrganisationEnhed"
    entity_class = OrganisationEnhed

    def __init__(self, organisationenhed):
        super(OrganisationEnhedConverter, self).__init__(organisationenhed)
        self.map = {
            u'Navn': organisationenhed.brugervendtnoegle,
            u'Nummer': organisationenhed.id,
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

class OrganisationFunktionConverter(SemaWiConverter):
    wiki_type_name = "OrganisationFunktion"
    entity_class = OrganisationFunktion

    def __init__(self, organisationfunktion):
        super(OrganisationFunktionConverter, self).__init__(organisationfunktion)
        self.map = {
            u'Navn': organisationfunktion.brugervendtnoegle,
            u'Nummer': organisationfunktion.id,
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
