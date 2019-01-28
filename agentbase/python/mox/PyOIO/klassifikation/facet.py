# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


#!/usr/bin/env python

from PyOIO.OIOCommon import OIOEntity


class Facet(OIOEntity):
    """Represents the OIO information model 1.1 Facet
    https://digitaliser.dk/resource/991439
    """

    ENTITY_CLASS = 'Facet'
    EGENSKABER_KEY = 'facetegenskaber'
    PUBLICERET_KEY = 'facetpubliceret'
    basepath = '/klassifikation/facet'

    egenskaber_keys = OIOEntity.egenskaber_keys + [
        'facetbeskrivelse', 'facetplan', 'facetopbygning',
        'facetophavsret', 'facetsupplement', 'retskilde'
    ]

    relation_keys = [
        'ansvarlig', 'ejer', 'facettilhoer', 'redaktoerer'
    ]
