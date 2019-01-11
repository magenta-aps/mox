# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


#!/usr/bin/env python

from PyOIO.OIOCommon import OIOEntity


class ItSystem(OIOEntity):
    """It-system
    from: Specifikation af serviceinterface for Organisation. Version 1.1
    """

    ENTITY_CLASS = 'Itsystem'
    EGENSKABER_KEY = 'itsystemegenskaber'
    GYLDIGHED_KEY = 'itsystemgyldighed'
    basepath = '/organisation/itsystem'

    egenskaber_keys = OIOEntity.egenskaber_keys + [
        'itsystemnavn', 'itsystemtype', 'konfigurationreference'
    ]
    name_key = 'itsystemnavn'
    type_key = 'itsystemtype'

    relation_keys = [
        'adresser', 'opgaver', 'systemtyper', 'tilhoerer',
        'tilknyttedeorganisationer', 'tilknyttedeenheder',
        'tilknyttedefunktioner', 'tilknyttedebrugere',
        'tilknyttedeinteressefaellesskaber', 'tilknyttedeitsystemer',
        'tilknyttedepersoner'
    ]
