#!/usr/bin/env python

from PyOIO.OIOCommon import OIOEntity


class Interessefaellesskab(OIOEntity):
    """Represents the OIO information model 1.1 Interessefaellesskab
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Interessefaellesskab'
    EGENSKABER_KEY = 'interessefaellesskabegenskaber'
    GYLDIGHED_KEY = 'interessefaellesskabgyldighed'
    basepath = '/organisation/interessefaellesskab'

    egenskaber_keys = OIOEntity.egenskaber_keys + [
        'interessefaellesskabsnavn', 'interessefaellesskabstype'
    ]
    name_key = 'interessefaellesskabsnavn'
    type_key = 'interessefaellesskabstype'

    relation_keys = [
        'adresser', 'branche', 'interessefaellesskabstype', 'opgaver',
        'overordnet', 'systemtyper', 'tilhoerer',
        'tilknyttedebrugere', 'tilknyttedeenheder', 'tilknyttedefunktioner',
        'tilknyttedeinteressefaellesskaber', 'tilknyttedeitsystemer',
        'tilknyttedeorganisationer', 'tilknyttedepersoner'
    ]
