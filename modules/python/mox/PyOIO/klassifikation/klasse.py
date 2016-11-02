#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIORelation, OIORelationContainer
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer
from PyOIO.OIOCommon import OIOGyldighed, OIOGyldighedContainer


class Klasse(OIOEntity):
    """Represents the OIO information model 1.1 Klasse
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Klasse'
    EGENSKABER_KEY = 'klasseegenskaber'
    GYLDIGHED_KEY = 'klassegyldighed'

    def __init__(self, lora, id):
        """ Args:
        lora:   Lora - the Lora handler object
        ID:     string - the GUID uniquely representing the Klasse
        """
        super(Klasse, self).__init__(lora, id)

    def parse_json(self):
        self.registreringer = []
        for index, registrering in enumerate(self.json['registreringer']):
            self.registreringer.append(KlasseRegistrering(self, index, registrering))

    @staticmethod
    def basepath():
        return "/klassifikation/klasse"


class KlasseRegistrering(OIORegistrering):

    def __init__(self, klasse, registrering_number, data):
        super(KlasseRegistrering, self).__init__(klasse, data, registrering_number)

        self.set_egenskaber(KlasseEgenskabContainer.from_json(self, self.json['attributter'][Klasse.EGENSKABER_KEY]))
        self.set_gyldighed(OIOGyldighedContainer.from_json(self, self.json['tilstande'][Klasse.GYLDIGHED_KEY]))
        self.set_relationer(OIORelationContainer.from_json(self, self.json['relationer']))


class KlasseEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(KlasseEgenskab, self).__init__(registrering, data)
        self.klassesnavn = data.get('klassesnavn') # 0..1
        self.klassestype = data.get('klassestype') # 0..1

    @property
    def name(self):
        return self.klassesnavn


class KlasseEgenskabContainer(OIOEgenskabContainer):

    @staticmethod
    def from_json(registrering, data):
        egenskaber = KlasseEgenskabContainer()
        for egenskab in data:
            egenskaber.append(KlasseEgenskab(registrering, egenskab))
        return egenskaber
