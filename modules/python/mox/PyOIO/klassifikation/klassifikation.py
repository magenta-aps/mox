#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer


class Klassifikation(OIOEntity):
    """Represents the OIO information model 1.1 Klassifikation
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Klassifikation'
    EGENSKABER_KEY = 'klassifikationegenskaber'
    GYLDIGHED_KEY = 'klassifikationgyldighed'
    basepath = '/klassifikation/klassifikation'


@Klassifikation.registrering_class
class KlassifikationRegistrering(OIORegistrering):

    @property
    def klassifikationkaldenavn(self):
        return self.get_egenskab('kaldenavn')

    @property
    def name(self):
        return self.klassifikationkaldenavn

    @property
    def klassifikationbeskrivelse(self):
        return self.get_egenskab('beskrivelse')

    @property
    def klassifikationophavsret(self):
        return self.get_egenskab('ophavsret')


@Klassifikation.egenskab_class
class KlassifikationEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(KlassifikationEgenskab, self).__init__(registrering, data)
        self.klassifikationkaldenavn = data.get('klassifikationkaldenavn')
        self.klassifikationbeskrivelse = data.get('klassifikationbeskrivelse')
        self.klassifikationophavsret = data.get('klassifikationophavsret')

    @property
    def name(self):
        return self.klassifikationkaldenavn
