#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer


class OrganisationFunktion(OIOEntity):
    """Represents the OIO information model 1.1 OrganisationFunktion
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'OrganisationFunktion'
    EGENSKABER_KEY = 'organisationfunktionegenskaber'
    GYLDIGHED_KEY = 'organisationfunktiongyldighed'
    basepath = '/organisation/organisationfunktion'


@OrganisationFunktion.registrering_class
class OrganisationFunktionRegistrering(OIORegistrering):

    @property
    def funktionsnavn(self):
        return self.get_egenskab('funktionsnavn')

    @property
    def name(self):
        return self.funktionsnavn


@OrganisationFunktion.egenskab_class
class OrganisationFunktionEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(OrganisationFunktionEgenskab, self).__init__(registrering, data)
        self.funktionsnavn = data.get('funktionsnavn')

    @property
    def name(self):
        return self.funktionsnavn
