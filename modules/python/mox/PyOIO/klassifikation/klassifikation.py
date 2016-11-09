#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load


class Klassifikation(OIOEntity):
    """Represents the OIO information model 1.1 Klassifikation
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Klassifikation'
    EGENSKABER_KEY = 'klassifikationegenskaber'
    GYLDIGHED_KEY = 'klassifikationgyldighed'
    basepath = '/klassifikation/klassifikation'

    egenskaber_keys = OIOEntity.egenskaber_keys + ['klassifikationkaldenavn', 'klassifikationbeskrivelse', 'klassifikationophavsret']
    name_key = 'klassifikationkaldenavn'
