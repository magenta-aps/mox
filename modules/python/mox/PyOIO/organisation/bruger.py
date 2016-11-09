#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer


class Bruger(OIOEntity):
    """Represents the OIO information model 1.1 Bruger
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Bruger'
    EGENSKABER_KEY = 'brugeregenskaber'
    GYLDIGHED_KEY = 'brugergyldighed'
    basepath = '/organisation/bruger'

    egenskaber_keys = OIOEntity.egenskaber_keys + ['brugernavn', 'brugertype']
    name_key = 'brugernavn'
    type_key = 'brugertype'


@Bruger.registrering_class
class BrugerRegistrering(OIORegistrering):
    pass


@Bruger.egenskab_class
class BrugerEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(BrugerEgenskab, self).__init__(registrering, data)
        self.brugernavn = data['brugernavn']
        self.brugertype = data.get('brugertype')

    @property
    def name(self):
        return self.brugernavn
