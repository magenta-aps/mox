#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer


class Interessefaellesskab(OIOEntity):
    """Represents the OIO information model 1.1 Interessefaellesskab
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Interessefaellesskab'
    EGENSKABER_KEY = 'interessefaellesskabegenskaber'
    GYLDIGHED_KEY = 'interessefaellesskabgyldighed'
    basepath = '/organisation/interessefaellesskab'


@Interessefaellesskab.registrering_class
class InteressefaellesskabRegistrering(OIORegistrering):

    @property
    def interessefaellesskabsnavn(self):
        return self.get_egenskab('interessefaellesskabsnavn')

    @property
    def name(self):
        return self.interessefaellesskabsnavn

    @property
    def interessefaellesskabstype(self):
        return self.get_egenskab('interessefaellesskabstype')

    @property
    def type(self):
        return self.interessefaellesskabstype


@Interessefaellesskab.egenskab_class
class InteressefaellesskabEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(InteressefaellesskabEgenskab, self).__init__(registrering, data)
        self.interessefaellesskabsnavn = data.get('interessefaellesskabsnavn')
        self.interessefaellesskabstype = data.get('interessefaellesskabstype')

    @property
    def name(self):
        return self.interessefaellesskabsnavn
