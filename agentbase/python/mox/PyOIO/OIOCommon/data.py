# Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import pytz
from datetime import datetime
from virkning import Virkning


class Item(object):

    def __init__(self, registrering, data):
        self.registrering = registrering
        self.virkning = Virkning(data['virkning'])
        self._data = data

    def get(self, name, default=None):
        return self._data.get(name, default)


class ItemContainer(list):

    def at(self, time):
        return [item for item in self if item.virkning.in_effect(time)]

    @property
    def current(self):
        return self.at(datetime.now(pytz.utc))
