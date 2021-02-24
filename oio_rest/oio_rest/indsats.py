# SPDX-FileCopyrightText: 2017-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

from .oio_base import OIORestObject, OIOStandardHierarchy


class Indsats(OIORestObject):
    """
    Implement an Indsats  - manage access to database layer from the API.
    """

    pass


class IndsatsHierarki(OIOStandardHierarchy):
    """Implement the Klassifikation Standard."""

    _name = "Indsats"
    _classes = [Indsats]
