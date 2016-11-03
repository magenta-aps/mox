#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer


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

    @staticmethod
    def basepath():
        return "/klassifikation/klasse"


@Klasse.registrering_class
class KlasseRegistrering(OIORegistrering):

    @property
    def beskrivelse(self):
        return self.get_egenskab('beskrivelse')

    @property
    def titel(self):
        return self.get_egenskab('titel')



@Klasse.egenskab_class
class KlasseEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(KlasseEgenskab, self).__init__(registrering, data)
        self.beskrivelse = data.get('beskrivelse')
        self.titel = data.get('titel')
        self.eksempel = data.get('eksempel')
        self.omfang = data.get('omfang')

    @property
    def name(self):
        return self.klassenavn
