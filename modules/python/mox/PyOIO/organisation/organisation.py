#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIORelation, OIORelationContainer
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer
from PyOIO.OIOCommon import OIOGyldighed, OIOGyldighedContainer


class Organisation(OIOEntity):
    """Represents the OIO information model 1.1 Organisation
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Organisation'
    EGENSKABER_KEY = 'organisationegenskaber'
    GYLDIGHED_KEY = 'organisationgyldighed'

    def __init__(self, lora, id):
        """ Args:
        lora:   Lora - the Lora handler object
        ID:     string - the GUID uniquely representing the Organisation
        """
        super(Organisation, self).__init__(lora, id)

    def load(self):
        super(Organisation, self).load()
        self.registreringer = []
        for index, registrering in enumerate(self.json['registreringer']):
            self.registreringer.append(OrganisationRegistrering(self, index, registrering))
        self.loaded()

    @staticmethod
    def basepath():
        return "/organisation/organisation"


class OrganisationRegistrering(OIORegistrering):

    def __init__(self, organisation, registrering_number, data):
        super(OrganisationRegistrering, self).__init__(organisation, data, registrering_number)

        self.set_egenskaber(OrganisationEgenskabContainer.from_json(self, self.json['attributter'][Organisation.EGENSKABER_KEY]))
        self.set_gyldighed(OIOGyldighedContainer.from_json(self, self.json['tilstande'][Organisation.GYLDIGHED_KEY]))
        self.set_relationer(OIORelationContainer.from_json(self, self.json['relationer']))


class OrganisationEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(OrganisationEgenskab, self).__init__(registrering, data)
        self.organisationsnavn = data.get('organisationsnavn') # 0..1

    @property
    def name(self):
        return self.organisationsnavn


class OrganisationEgenskabContainer(OIOEgenskabContainer):

    @staticmethod
    def from_json(registrering, data):
        egenskaber = OrganisationEgenskabContainer()
        for egenskab in data:
            egenskaber.append(OrganisationEgenskab(registrering, egenskab))
        return egenskaber
