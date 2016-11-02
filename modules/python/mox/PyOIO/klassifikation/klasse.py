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

    @staticmethod
    def basepath():
        return "/klassifikation/klasse"


@Klasse.registrering_class
class KlasseRegistrering(OIORegistrering):
    pass


@Klasse.egenskab_class
class KlasseEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(KlasseEgenskab, self).__init__(registrering, data)
        self.klassenavn = data.get('klassenavn') # 0..1
        self.klassetype = data.get('klassetype') # 0..1

    @property
    def name(self):
        return self.klassenavn
