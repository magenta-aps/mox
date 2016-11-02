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

    @staticmethod
    def basepath():
        return "/organisation/bruger"


@Bruger.registrering_class
class BrugerRegistrering(OIORegistrering):
    pass


@Bruger.egenskab_class
class BrugerEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(BrugerEgenskab, self).__init__(registrering, data)
        self.brugernavn = data['brugernavn'] # 0..1
        self.brugertype = data.get('brugertype')

    @property
    def name(self):
        return self.brugernavn
