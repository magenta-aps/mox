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

    egenskaber_keys = OIOEntity.egenskaber_keys + ['interessefaellesskabsnavn', 'interessefaellesskabstype']
    name_key = 'interessefaellesskabsnavn'
    type_key = 'interessefaellesskabstype'


@Interessefaellesskab.registrering_class
class InteressefaellesskabRegistrering(OIORegistrering):
    pass


@Interessefaellesskab.egenskab_class
class InteressefaellesskabEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(InteressefaellesskabEgenskab, self).__init__(registrering, data)
        self.interessefaellesskabsnavn = data.get('interessefaellesskabsnavn')
        self.interessefaellesskabstype = data.get('interessefaellesskabstype')

    @property
    def name(self):
        return self.interessefaellesskabsnavn
