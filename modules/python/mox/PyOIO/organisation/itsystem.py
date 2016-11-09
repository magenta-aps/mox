#!/usr/bin/env python

from PyOIO.OIOCommon import Virkning, OIOEntity, OIORegistrering, InvalidOIOException, requires_load


class ItSystem(OIOEntity):
    """It-system
    from: Specifikation af serviceinterface for Organisation. Version 1.1
    """

    ENTITY_CLASS = 'Itsystem'
    EGENSKABER_KEY = 'itsystemegenskaber'
    GYLDIGHED_KEY = 'itsystemgyldighed'
    basepath = '/organisation/itsystem'

    egenskaber_keys = OIOEntity.egenskaber_keys + ['itsystemnavn', 'itsystemtype', 'konfigurationreference']
    name_key = 'itsystemnavn'
    type_key = 'itsystemtype'
