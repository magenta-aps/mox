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

    def __init__(self, lora, id):
        """ Args:
        lora:   Lora - the Lora handler object
        ID:     string - the GUID uniquely representing the Facet
        """
        super(Facet, self).__init__(lora, id)


@Facet.registrering_class
class FacetRegistrering(OIORegistrering):

    @property
    def beskrivelse(self):
        return self.get_egenskab('beskrivelse')


@Facet.egenskab_class
class FacetEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(FacetEgenskab, self).__init__(registrering, data)
        self.beskrivelse = data.get('beskrivelse')
