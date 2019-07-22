# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from .oio_base import OIORestObject, OIOStandardHierarchy


class LogHaendelse(OIORestObject):
    """
    Implement a log entry  - manage access to database layer from the API.
    """
    pass


class LogHierarki(OIOStandardHierarchy):
    """Implement the LogHaendelse Standard."""

    _name = "Log"
    _classes = [LogHaendelse]
