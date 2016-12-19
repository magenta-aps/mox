#!/usr/bin/env python

from PyOIO.OIOCommon import OIOEntity


class Facet(OIOEntity):
    """Represents the OIO information model 1.1 Facet
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Facet'
    EGENSKABER_KEY = 'facetegenskaber'
    PUBLICERET_KEY = 'facetpubliceret'
    basepath = '/klassifikation/facet'

    egenskaber_keys = OIOEntity.egenskaber_keys + [
        'facetbeskrivelse', 'facetplan', 'facetopbygning',
        'facetophavsret', 'facetsupplement', 'retskilde'
    ]

    relation_keys = [
        'ansvarlig', 'ejer', 'facettilhoer', 'redaktoerer'
    ]
