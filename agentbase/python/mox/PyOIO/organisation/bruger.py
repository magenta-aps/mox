# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


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
