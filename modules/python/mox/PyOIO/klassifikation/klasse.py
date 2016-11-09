#!/usr/bin/env python

from PyOIO.OIOCommon import OIOEntity


class Klasse(OIOEntity):
    """Represents the OIO information model 1.1 Klasse
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Klasse'
    EGENSKABER_KEY = 'klasseegenskaber'
    GYLDIGHED_KEY = 'klassegyldighed'
    basepath = '/klassifikation/klasse'

    egenskaber_keys = OIOEntity.egenskaber_keys + ['klassebeskrivelse', 'klassetitel', 'klasseeksempel', 'klasseomfang', 'aendringsnotat', 'retskilde']
    name_key = 'klassetitel'
