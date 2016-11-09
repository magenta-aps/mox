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


@Facet.registrering_class
class FacetRegistrering(OIORegistrering):

    @property
    def facetbeskrivelse(self):
        return self.get_egenskab('facetbeskrivelse')

    @property
    def facetplan(self):
        return self.get_egenskab('facetplan')

    @property
    def facetopbygning(self):
        return self.get_egenskab('facetopbygning')

    @property
    def facetophavsret(self):
        return self.get_egenskab('facetophavsret')

    @property
    def facetsupplement(self):
        return self.get_egenskab('facetsupplement')

    @property
    def retskilde(self):
        return self.get_egenskab('retskilde')


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