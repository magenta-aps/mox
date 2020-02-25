# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


from functools import wraps

import flask_saml_sso

from . import settings


def requires_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if settings.SAML_AUTH_ENABLE:
            flask_saml_sso.check_saml_authentication()
        return f(*args, **kwargs)

    return decorated


def get_authenticated_user():
    """Return hardcoded UUID if authentication is switched off."""
    # if settings.USE_SAML_AUTHENTICATION:
    #     return request.saml_user_id
    # else:
    #     return "42c432e8-9c4a-11e6-9f62-873cf34a735f"

    # Yes, this is a code smell. The idea originally was that all users that
    # interacted with lora also were in the database. This is not the case
    # anymore and is just legacy stuff. To refactor you would have to remove
    # that user_ref from all the stored procedures.
    return "42c432e8-9c4a-11e6-9f62-873cf34a735f"
