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

    egenskaber_keys = OIOEntity.egenskaber_keys + ['klassifikationkaldenavn', 'klassifikationbeskrivelse', 'klassifikationophavsret']
    name_key = 'klassifikationkaldenavn'


@Klassifikation.registrering_class
class KlassifikationRegistrering(OIORegistrering):
    pass


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
