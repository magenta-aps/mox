# SPDX-FileCopyrightText: 2016-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from .oio_base import OIORestObject, OIOStandardHierarchy


class Aktivitet(OIORestObject):
    """
    Implement an Aktivitet  - manage access to database layer from the API.
    """
    pass


class AktivitetsHierarki(OIOStandardHierarchy):
    """Implement the Klassifikation Standard."""

    _name = "Aktivitet"
    _classes = [Aktivitet]
