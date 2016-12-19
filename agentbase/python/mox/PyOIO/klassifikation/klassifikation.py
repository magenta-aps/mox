#!/usr/bin/env python

from PyOIO.OIOCommon import OIOEntity


class Klassifikation(OIOEntity):
    """Represents the OIO information model 1.1 Klassifikation
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Klassifikation'
    EGENSKABER_KEY = 'klassifikationegenskaber'
    PUBLICERET_KEY = 'klassifikationpubliceret'
    basepath = '/klassifikation/klassifikation'

    egenskaber_keys = OIOEntity.egenskaber_keys + [
        'klassifikationkaldenavn', 'klassifikationbeskrivelse',
        'klassifikationophavsret'
    ]
    name_key = 'klassifikationkaldenavn'

    relation_keys = [
        'ansvarlig', 'ejer', 'erstatter', 'facet', 'lovligekombinationer',
        'mapninger', 'overordnet', 'redaktoerer', 'sideordnede', 'tilfoejelser'
    ]
