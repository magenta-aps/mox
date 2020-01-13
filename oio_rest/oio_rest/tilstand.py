# SPDX-FileCopyrightText: 2017-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from .oio_base import OIORestObject, OIOStandardHierarchy


class Tilstand(OIORestObject):
    """
    Implement a Tilstand - manage access to database layer from the API.
    """
    pass


class TilstandsHierarki(OIOStandardHierarchy):
    """Implement the Klassifikation Standard."""

    _name = "Tilstand"
    _classes = [Tilstand]
