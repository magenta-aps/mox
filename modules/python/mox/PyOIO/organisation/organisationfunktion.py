#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load


class OrganisationFunktion(OIOEntity):
    """Represents the OIO information model 1.1 OrganisationFunktion
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'OrganisationFunktion'
    EGENSKABER_KEY = 'organisationfunktionegenskaber'
    GYLDIGHED_KEY = 'organisationfunktiongyldighed'
    basepath = '/organisation/organisationfunktion'

    egenskaber_keys = OIOEntity.egenskaber_keys + ['funktionsnavn']
    name_key = 'funktionsnavn'
