# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


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

    relation_keys = [
        'adresser', 'ansatte', 'branche', 'myndighed', 'myndighedstype',
        'opgaver', 'overordnet', 'produktionsenhed', 'skatteenhed',
        'tilhoerer', 'tilknyttedebrugere', 'tilknyttedeenheder',
        'tilknyttedefunktioner', 'tilknyttedeinteressefaellesskaber',
        'tilknyttedeitsystemer', 'tilknyttedeorganisationer',
        'tilknyttedepersoner', 'virksomhed', 'virksomhedstype'
    ]
