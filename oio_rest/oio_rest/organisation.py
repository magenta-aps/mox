# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from .oio_base import OIORestObject, OIOStandardHierarchy


class Bruger(OIORestObject):
    """
    Implement a Bruger  - manage access to database layer from the API.
    """
    pass


class InteresseFaellesskab(OIORestObject):
    """
    Implement an InteresseFaellesskab - manage access to database layer from
    the API.
    """
    pass


class ItSystem(OIORestObject):
    """
    Implement an ItSystem  - manage access to database from the API.
    """
    pass


class Organisation(OIORestObject):
    """
    Implement an Organisation  - manage access to database from the API.
    """
    pass


class OrganisationEnhed(OIORestObject):
    """
    Implement an OrganisationEnhed - manage access to database from the API.
    """
    pass


class OrganisationFunktion(OIORestObject):
    """
    Implement an OrganisationFunktion.
    """
    pass


class OrganisationsHierarki(OIOStandardHierarchy):
    """Implement the Organisation Standard."""

    _name = "Organisation"
    _classes = [Bruger, InteresseFaellesskab, ItSystem, Organisation,
                OrganisationEnhed, OrganisationFunktion]
