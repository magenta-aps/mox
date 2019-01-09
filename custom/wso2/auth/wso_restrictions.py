# Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


"""WSO2 specific handling of role-based access control.

The concept here is very simple:

* If you have the ADMIN_ROLE, you can read and edit everything.
* If you have the READONLY_ROLE, you can read everything.
* However, if you have the BLOCKED_ROLE, you cannot do anything.
"""

from flask import request
from restrictions import Operation

# TODO: Get these values from settings.
ADMIN_ROLE = "Internal/mox"
READONLY_ROLE = "Internal/readonly"
BLOCKED_ROLE = "Internal/blocked"


def get_auth_restrictions(user, object_type, operation):
    """WSO2 SAML token implementation of RBAC."""
    ALLOWED = None
    FORBIDDEN = []

    try:
        roles = request.saml_attributes['http://wso2.org/claims/role'][0]
        roles = roles.split(",")
        is_read_operation = operation == Operation.READ

        if BLOCKED_ROLE in roles:
            return FORBIDDEN
        elif ADMIN_ROLE in roles:
            return ALLOWED
        elif READONLY_ROLE in roles:
            return ALLOWED if is_read_operation else FORBIDDEN
        else:
            return FORBIDDEN
    except IndexError:
        # No role = denied
        return FORBIDDEN
