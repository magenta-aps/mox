# SPDX-FileCopyrightText: 2016-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

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
