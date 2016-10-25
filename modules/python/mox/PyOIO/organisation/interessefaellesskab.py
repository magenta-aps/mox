#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIORelation, OIORelationContainer
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer
from PyOIO.OIOCommon import OIOGyldighed, OIOGyldighedContainer


class Interessefaellesskab(OIOEntity):
    """Represents the OIO information model 1.1 Interessefaellesskab
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Interessefaellesskab'
    EGENSKABER_KEY = 'interessefaellesskabegenskaber'
    GYLDIGHED_KEY = 'interessefaellesskabgyldighed'

    def __init__(self, lora, id):
        """ Args:
        lora:   Lora - the Lora handler object
        ID:     string - the GUID uniquely representing the Interessefaellesskab
        """
        super(Interessefaellesskab, self).__init__(lora, id)

    def load(self):
        super(Interessefaellesskab, self).load()
        self.registreringer = []
        for index, registrering in enumerate(self.json['registreringer']):
            self.registreringer.append(InteressefaellesskabRegistrering(self, index, registrering))
        self.loaded()

    @staticmethod
    def basepath():
        return "/organisation/interessefaellesskab"


class InteressefaellesskabRegistrering(OIORegistrering):

    def __init__(self, interessefaellesskab, registrering_number, data):
        super(InteressefaellesskabRegistrering, self).__init__(interessefaellesskab, data, registrering_number)

        self.set_egenskaber(InteressefaellesskabEgenskabContainer.from_json(self, self.json['attributter'][Interessefaellesskab.EGENSKABER_KEY]))
        self.set_gyldighed(OIOGyldighedContainer.from_json(self, self.json['tilstande'][Interessefaellesskab.GYLDIGHED_KEY]))
        self.set_relationer(OIORelationContainer.from_json(self, self.json['relationer']))


class InteressefaellesskabEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(InteressefaellesskabEgenskab, self).__init__(registrering, data)
        self.interessefaellesskabsnavn = data.get('interessefaellesskabsnavn') # 0..1
        self.interessefaellesskabstype = data.get('interessefaellesskabstype') # 0..1

    @property
    def name(self):
        return self.interessefaellesskabsnavn


class InteressefaellesskabEgenskabContainer(OIOEgenskabContainer):

    @staticmethod
    def from_json(registrering, data):
        egenskaber = InteressefaellesskabEgenskabContainer()
        for egenskab in data:
            egenskaber.append(InteressefaellesskabEgenskab(registrering, egenskab))
        return egenskaber
