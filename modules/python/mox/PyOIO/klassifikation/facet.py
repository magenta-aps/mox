#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer


class Facet(OIOEntity):
    """Represents the OIO information model 1.1 Facet
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Facet'
    EGENSKABER_KEY = 'facetegenskaber'
    GYLDIGHED_KEY = 'facetgyldighed'
    basepath = '/klassifikation/facet'

    egenskaber_keys = OIOEntity.egenskaber_keys + ['facetbeskrivelse', 'facetplan', 'facetopbygning', 'facetophavsret', 'facetsupplement', 'retskilde']


@Facet.registrering_class
class FacetRegistrering(OIORegistrering):
    pass


@Facet.egenskab_class
class FacetEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(FacetEgenskab, self).__init__(registrering, data)
        self.facetbeskrivelse = data.get('facetbeskrivelse')
        self.facetplan = data.get('facetplan')
        self.facetopbygning = data.get('facetopbygning')
        self.facetophavsret = data.get('facetophavsret')
        self.facetsupplement = data.get('facetsupplement')
        self.retskilde = data.get('retskilde')