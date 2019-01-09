# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


from data import Item, ItemContainer
from exceptions import InvalidOIOException


class OIOPubliceret(Item):
    tilstande = ['Publiceret', 'IkkePubliceret']

    def __init__(self, registrering, data):
        super(OIOPubliceret, self).__init__(registrering, data)
        publiceret = data['publiceret']
        if publiceret in OIOPubliceret.tilstande:
            self.publiceret = publiceret
        else:
            raise InvalidOIOException('Invalid publiceret "%s"' % publiceret)

    # @property
    # def value(self):
    #     return self.publiceret

    @staticmethod
    def from_json(registrering, json):
        return OIOPubliceret(registrering, json)


class OIOPubliceretContainer(ItemContainer):

    @staticmethod
    def from_json(registrering, json):
        container = OIOPubliceretContainer()
        for publiceret in json:
            container.append(OIOPubliceret.from_json(registrering, publiceret))
        return container
