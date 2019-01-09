# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


# encoding: utf-8

from .oio_rest import OIORestObject, OIOStandardHierarchy


class Sag(OIORestObject):
    """
    Implement a Sag  - manage access to database layer from the API.
    """
    pass


class SagsHierarki(OIOStandardHierarchy):
    """Implement the Klassifikation Standard."""

    _name = "Sag"
    _classes = [Sag]
