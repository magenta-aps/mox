#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering
from PyOIO.OIOCommon import OIORelationContainer
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer
from PyOIO.OIOCommon import OIOGyldighedContainer


class Bruger(OIOEntity):
    """Represents the OIO information model 1.1 Bruger
    https://digitaliser.dk/resource/991439

    """

    ENTITY_CLASS = 'Bruger'
    EGENSKABER_KEY = 'brugeregenskaber'
    GYLDIGHED_KEY = 'brugergyldighed'

    def __init__(self, lora, id):
        """ Args:
        lora:   Lora - the Lora handler object
        ID:     string - the GUID uniquely representing the Bruger
        """
        super(Bruger, self).__init__(lora, id)

    def load(self):
        super(Bruger, self).load()
        self.registreringer = []
        for index, registrering in enumerate(self.json['registreringer']):
            self.registreringer.append(BrugerRegistrering(self, index, registrering))
        self.loaded()

    @staticmethod
    def basepath():
        return "/organisation/bruger"


class BrugerRegistrering(OIORegistrering):

    def __init__(self, bruger, registrering_number, data):
        super(BrugerRegistrering, self).__init__(bruger, data, registrering_number)

        self.set_egenskaber(BrugerEgenskabContainer.from_json(self, self.json['attributter'][Bruger.EGENSKABER_KEY]))
        self.set_gyldighed(OIOGyldighedContainer.from_json(self, self.json['tilstande'][Bruger.GYLDIGHED_KEY]))
        self.set_relationer(OIORelationContainer.from_json(self, self.json['relationer']))


class BrugerEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(BrugerEgenskab, self).__init__(registrering, data)
        self.brugernavn = data['brugernavn'] # 0..1
        self.brugertype = data.get('brugertype')

    @property
    def name(self):
        return self.brugernavn


class BrugerEgenskabContainer(OIOEgenskabContainer):

    @staticmethod
    def from_json(registrering, data):
        egenskaber = BrugerEgenskabContainer()
        for egenskab in data:
            egenskaber.append(BrugerEgenskab(registrering, egenskab))
        return egenskaber
