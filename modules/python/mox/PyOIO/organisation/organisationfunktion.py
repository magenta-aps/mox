#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIORelation, OIORelationContainer
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer
from PyOIO.OIOCommon import OIOGyldighed, OIOGyldighedContainer


class OrganisationFunktion(OIOEntity):
    """Represents the OIO information model 1.1 OrganisationFunktion
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'OrganisationFunktion'
    EGENSKABER_KEY = 'organisationfunktionegenskaber'
    GYLDIGHED_KEY = 'organisationfunktiongyldighed'

    def __init__(self, lora, id):
        """ Args:
        lora:   Lora - the Lora handler object
        ID:     string - the GUID uniquely representing the OrganisationFunktion
        """
        super(OrganisationFunktion, self).__init__(lora, id)

    def load(self):
        super(OrganisationFunktion, self).load()
        self.registreringer = []
        for index, registrering in enumerate(self.json['registreringer']):
            self.registreringer.append(OrganisationFunktionRegistrering(self, index, registrering))
        self.loaded()

    @staticmethod
    def basepath():
        return "/organisation/organisationfunktion"


class OrganisationFunktionRegistrering(OIORegistrering):

    def __init__(self, organisationfunktion, registrering_number, data):
        super(OrganisationFunktionRegistrering, self).__init__(organisationfunktion, data, registrering_number)

        self.set_egenskaber(OrganisationFunktionEgenskabContainer.from_json(self, self.json['attributter'][OrganisationFunktion.EGENSKABER_KEY]))
        self.set_gyldighed(OIOGyldighedContainer.from_json(self, self.json['tilstande'][OrganisationFunktion.GYLDIGHED_KEY]))
        self.set_relationer(OIORelationContainer.from_json(self, self.json['relationer']))


class OrganisationFunktionEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(OrganisationFunktionEgenskab, self).__init__(registrering, data)
        self.funktionsnavn = data.get('funktionsnavn') # 0..1

    @property
    def name(self):
        return self.funktionsnavn


class OrganisationFunktionEgenskabContainer(OIOEgenskabContainer):

    @staticmethod
    def from_json(registrering, data):
        egenskaber = OrganisationFunktionEgenskabContainer()
        for egenskab in data:
            egenskaber.append(OrganisationFunktionEgenskab(registrering, egenskab))
        return egenskaber
