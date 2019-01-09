# Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


from data import Item, ItemContainer
from exceptions import InvalidOIOException


class OIOGyldighed(Item):
    gyldige_tilstande = ['Aktiv', 'Inaktiv']

    def __init__(self, registrering, data):
        super(OIOGyldighed, self).__init__(registrering, data)
        gyldighed = data['gyldighed']
        if gyldighed in OIOGyldighed.gyldige_tilstande:
            self.gyldighed = gyldighed
        else:
            raise InvalidOIOException('Invalid gyldighed "%s"' % gyldighed)

    @staticmethod
    def from_json(registrering, json):
        return OIOGyldighed(registrering, json)


class OIOGyldighedContainer(ItemContainer):

    @staticmethod
    def from_json(registrering, json):
        container = OIOGyldighedContainer()
        for gyldighed in json:
            container.append(OIOGyldighed.from_json(registrering, gyldighed))
        return container
