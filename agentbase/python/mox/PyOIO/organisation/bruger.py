#!/usr/bin/env python

from PyOIO.OIOCommon import OIOEntity


class Bruger(OIOEntity):
    """Represents the OIO information model 1.1 Bruger
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Bruger'
    EGENSKABER_KEY = 'brugeregenskaber'
    GYLDIGHED_KEY = 'brugergyldighed'
    basepath = '/organisation/bruger'

    egenskaber_keys = OIOEntity.egenskaber_keys + ['brugernavn', 'brugertype']
    name_key = 'brugernavn'
    type_key = 'brugertype'

    relation_keys = [
        'adresser', 'brugertyper', 'opgaver', 'tilhoerer',
        'tilknyttedeorganisationer', 'tilknyttedeenheder',
        'tilknyttedefunktioner', 'tilknyttedeinteressefaellesskaber',
        'tilknyttedeitsystemer', 'tilknyttedepersoner'
    ]
