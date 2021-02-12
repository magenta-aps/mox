# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from .oio_base import OIORestObject, OIOStandardHierarchy


class Sag(OIORestObject):
    """
    Implement a Sag  - manage access to database layer from the API.
    """

    pass


class SagsHierarki(OIOStandardHierarchy):
    """Implement the Klassifikation Standard."""

    _name = "Sag"
    _classes = [Sag]
