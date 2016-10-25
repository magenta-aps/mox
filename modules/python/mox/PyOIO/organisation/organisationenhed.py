#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIORelation, OIORelationContainer
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer
from PyOIO.OIOCommon import OIOGyldighed, OIOGyldighedContainer


class OrganisationEnhed(OIOEntity):
    """Represents the OIO information model 1.1 OrganisationEnhed
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'OrganisationEnhed'
    EGENSKABER_KEY = 'organisationenhedegenskaber'
    GYLDIGHED_KEY = 'organisationenhedgyldighed'

    def __init__(self, lora, id):
        """ Args:
        lora:   Lora - the Lora handler object
        ID:     string - the GUID uniquely representing the OrganisationEnhed
        """
        super(OrganisationEnhed, self).__init__(lora, id)

    def load(self):
        super(OrganisationEnhed, self).load()
        self.registreringer = []
        for index, registrering in enumerate(self.json['registreringer']):
            self.registreringer.append(OrganisationEnhedRegistrering(self, index, registrering))
        self.loaded()

    @staticmethod
    def basepath():
        return "/organisation/organisationenhed"


class OrganisationEnhedRegistrering(OIORegistrering):

    def __init__(self, organisationenhed, registrering_number, data):
        super(OrganisationEnhedRegistrering, self).__init__(organisationenhed, data, registrering_number)

        self.set_egenskaber(OrganisationEnhedEgenskabContainer.from_json(self, self.json['attributter'][OrganisationEnhed.EGENSKABER_KEY]))
        self.set_gyldighed(OIOGyldighedContainer.from_json(self, self.json['tilstande'][OrganisationEnhed.GYLDIGHED_KEY]))
        self.set_relationer(OIORelationContainer.from_json(self, self.json['relationer']))


class OrganisationEnhedEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(OrganisationEnhedEgenskab, self).__init__(registrering, data)
        self.enhedsnavn = data.get('enhedsnavn') # 0..1

    @property
    def name(self):
        return self.enhedsnavn


class OrganisationEnhedEgenskabContainer(OIOEgenskabContainer):

    @staticmethod
    def from_json(registrering, data):
        egenskaber = OrganisationEnhedEgenskabContainer()
        for egenskab in data:
            egenskaber.append(OrganisationEnhedEgenskab(registrering, egenskab))
        return egenskaber
