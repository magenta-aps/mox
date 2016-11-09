#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load
from PyOIO.OIOCommon import OIOEgenskab, OIOEgenskabContainer


class Klasse(OIOEntity):
    """Represents the OIO information model 1.1 Klasse
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Klasse'
    EGENSKABER_KEY = 'klasseegenskaber'
    GYLDIGHED_KEY = 'klassegyldighed'
    basepath = '/klassifikation/klasse'

    egenskaber_keys = ['klassebeskrivelse', 'klassetitel', 'klasseeksempel', 'klasseomfang', 'aendringsnotat', 'retskilde']


@Klasse.registrering_class
class KlasseRegistrering(OIORegistrering):
    pass


@Klasse.egenskab_class
class KlasseEgenskab(OIOEgenskab):

    def __init__(self, registrering, data):
        super(KlasseEgenskab, self).__init__(registrering, data)
        self.klassebeskrivelse = data.get('klassebeskrivelse')
        self.klassetitel = data.get('klassetitel')
        self.klasseeksempel = data.get('klasseeksempel')
        self.klasseomfang = data.get('klasseomfang')
        self.aendringsnotat = data.get('aendringsnotat')
        self.retskilde = data.get('retskilde')

    @property
    def name(self):
        return self.klassenavn
