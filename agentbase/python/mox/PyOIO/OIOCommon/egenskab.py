# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


from data import Item, ItemContainer


class OIOEgenskab(Item):
    def __init__(self, registrering, data):
        super(OIOEgenskab, self).__init__(registrering, data)
        self.brugervendtnoegle = data['brugervendtnoegle']

    @property
    def name(self):
        return self.brugervendtnoegle

    def __repr__(self):
        return '%sEgenskab("%s - %s")' % (
            self.registrering.entity.ENTITY_CLASS,
            self.brugervendtnoegle, self.name
        )

    def __str__(self):
        return '%sEgenskab: %s "%s - %s"' % (
            self.registrering.entity.ENTITY_CLASS,
            self.registrering.entity.ENTITY_CLASS,
            self.brugervendtnoegle, self.name
        )

    def __getattr__(self, name):
        if name in self.registrering.entity.egenskaber_keys:
            return self.get(name, u'')


class OIOEgenskabContainer(ItemContainer):

    @staticmethod
    def from_json(registrering, data, egenskab_class):
        egenskaber = OIOEgenskabContainer()
        for egenskab in data:
            egenskaber.append(egenskab_class(registrering, egenskab))
        return egenskaber
