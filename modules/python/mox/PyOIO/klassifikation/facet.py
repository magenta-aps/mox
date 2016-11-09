#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load


class Facet(OIOEntity):
    """Represents the OIO information model 1.1 Facet
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Facet'
    EGENSKABER_KEY = 'facetegenskaber'
    GYLDIGHED_KEY = 'facetgyldighed'
    basepath = '/klassifikation/facet'

    egenskaber_keys = OIOEntity.egenskaber_keys + ['facetbeskrivelse', 'facetplan', 'facetopbygning', 'facetophavsret', 'facetsupplement', 'retskilde']
