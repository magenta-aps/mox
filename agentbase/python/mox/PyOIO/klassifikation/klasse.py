# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


#!/usr/bin/env python

from PyOIO.OIOCommon import OIOEntity


class Klasse(OIOEntity):
    """Represents the OIO information model 1.1 Klasse
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Klasse'
    EGENSKABER_KEY = 'klasseegenskaber'
    PUBLICERET_KEY = 'klassepubliceret'
    basepath = '/klassifikation/klasse'

    egenskaber_keys = OIOEntity.egenskaber_keys + [
        'klassebeskrivelse', 'klassetitel', 'klasseeksempel',
        'klasseomfang', 'aendringsnotat', 'retskilde', 'soegeord'
    ]
    name_key = 'klassetitel'

    relation_keys = [
        'ansvarlig', 'ejer', 'erstatter', 'facet', 'lovligekombinationer'
        'mapninger', 'overordnet', 'redaktoerer', 'sideordnede', 'tilfoejelser'
    ]
