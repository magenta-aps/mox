#!/usr/bin/env python

from PyOIO.OIOCommon import OIOEntity


class Organisation(OIOEntity):
    """Represents the OIO information model 1.1 Organisation
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Organisation'
    EGENSKABER_KEY = 'organisationegenskaber'
    GYLDIGHED_KEY = 'organisationgyldighed'
    basepath = '/organisation/organisation'

    egenskaber_keys = OIOEntity.egenskaber_keys + ['organisationsnavn']
    name_key = 'organisationsnavn'
