# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""
    settings.py
    ~~~~~~~~~~~

    This module contains all global ``oio_rest`` settings.

    It contains default values for all options, all of which can be overwritten
    by environment variables of the same name. Setting the environment variable
    ``CONFIG_FILE`` to a file containing JSON setting:value pairs, will
    overwrite the settings once again (file having highest precedens).
"""

import collections
import contextlib
import importlib
import itertools
import json
import os


CONFIG_FILE = os.getenv('OIO_REST_CONFIG_FILE', None)
BASE_URL = os.getenv('BASE_URL', '')


# Database (PostgreSQL) settings
DB_HOST = os.getenv('DB_HOST', "localhost")
DB_PORT = int(os.getenv('DB_PORT', '0')) or None
DB_USER = os.getenv('DB_USER', "mox")
DB_PASSWORD = os.getenv('DB_PASSWORD', "mox")

# name of database, should be changed to use DB_ convention.
DATABASE = os.getenv('DB_NAME' ,"mox")

# Per-process limits on the amount of database connections. Setting the minimum
# to a non-zero value ensures that the webapp opens this amount at load,
# failing if the database isn't available.
DB_MIN_CONNECTIONS = int(os.getenv('DB_MIN_CONNECTIONS', '0'))
DB_MAX_CONNECTIONS = int(os.getenv('DB_MAX_CONNECTIONS', '10'))
DB_STRUCTURE = os.getenv('DB_STRUCTURE', 'oio_rest.db.db_structure')

# This is where file uploads are stored. It must be readable and writable by
# the mox user, running the REST API server. This is used in the Dokument
# hierarchy.
FILE_UPLOAD_FOLDER = os.getenv('FILE_UPLOAD_FOLDER', '/var/mox')

# The Endpoint specified in the AppliesTo element of the STS request
# This will be used to verify the Audience of the SAML Assertion
SAML_MOX_ENTITY_ID = os.getenv('SAML_MOX_ENTITY_ID', 'https://saml.local')

# The Entity ID of the IdP. Used to verify the token Issuer --
# specified in AD FS as the Federation Service identifier.
# Example: 'http://fs.contoso.com/adfs/services/trust'
SAML_IDP_ENTITY_ID = os.getenv('SAML_IDP_ENTITY_ID', 'localhost')

# The URL on which to access the SAML IdP.
# Example: 'https://fs.contoso.com/adfs/services/trust/13/UsernameMixed'
SAML_IDP_URL = os.getenv(
    'SAML_IDP_URL',
    'https://localhost:9443/services/wso2carbon-sts.wso2carbon-stsHttpsEndpoint'
)

# We currently support authentication against 'wso2' and 'adfs'
SAML_IDP_TYPE = os.getenv('SAML_IDP_TYPE', 'wso2')

# The public certificate file of the IdP, in PEM-format.
SAML_IDP_CERTIFICATE = os.getenv(
    'SAML_IDP_CERTIFICATE',
    'test_auth_data/idp-certificate.pem'
)

# Whether to enable SAML authentication
USE_SAML_AUTHENTICATION = os.getenv('USE_SAML_AUTHENTICATION', False)

# SAML user ID attribute -- default is for WSO2
# Example:
#   http://schemas.xmlsoap.org
#       /ws/2005/05/identity/claims/privatepersonalidentifier
SAML_USER_ID_ATTIBUTE = os.getenv(
    'SAML_USER_ID_ATTIBUTE',
    'http://wso2.org/claims/url'
)

# Whether authorization is enabled.
# If not, the restrictions module is not called.
DO_ENABLE_RESTRICTIONS = os.getenv('DO_ENABLE_RESTRICTIONS', False)

# The module which implements the authorization restrictions.
# Must be present in sys.path.
AUTH_RESTRICTION_MODULE = os.getenv(
    'AUTH_RESTRICTION_MODULE',
    'oio_rest.auth.wso_restrictions',
)

# The name of the function which retrieves the restrictions.
# Must be present in AUTH_RESTRICTION_MODULE and have the correct signature.
AUTH_RESTRICTION_FUNCTION = os.getenv(
    'AUTH_RESTRICTION_FUNCTION',
    'get_auth_restrictions',
)

# Log AMQP settings
LOG_AMQP_SERVER = os.getenv('LOG_AMQP_SERVER', 'localhost')
MOX_LOG_EXCHANGE = os.getenv('MOX_LOG_EXCHANGE', 'mox.log')
MOX_LOG_QUEUE = os.getenv('MOX_LOG_QUEUE', 'mox.log_queue')

LOG_IGNORED_SERVICES = ['Log', ]

AUDIT_LOG_FILE = os.getenv('AUDIT_LOG_FILE', '/var/log/mox/audit.log')

SAML_IDP_METADATA_URL = os.getenv(
    'SAML_IDP_METADATA_URL',
    'https://172.16.20.100/simplesaml/saml2/idp/metadata.php'
)
SAML_IDP_INSECURE = os.getenv('SAML_IDP_INSECURE', False)
SAML_REQUESTS_SIGNED = os.getenv('SAML_REQUESTS_SIGNED', False)
SAML_KEY_FILE = os.getenv('SAML_KEY_FILE', None)
SAML_CERT_FILE = os.getenv('SAML_CERT_FILE', None)
SAML_AUTH_ENABLE = os.getenv('SAML_AUTH_ENABLE', False)

SQLALCHEMY_DATABASE_URI = os.getenv(
    'SQLALCHEMY_DATABASE_URI',
    "postgresql://sessions:sessions@127.0.0.1/sessions",
)
SESSION_PERMANENT = os.getenv('SESSION_PERMANENT', True)
PERMANENT_SESSION_LIFETIME = os.getenv('PERMANENT_SESSION_LIFETIME', 3600)


def update_config(mapping, config_path):
    """load the JSON configuration at the given path """
    if config_path is None:
        return
    try:
        with open(config_path) as fp:
            overrides = json.load(fp)
    except IOError:
        print('Unable to read config {}'.format(config_path))
    else:
        mapping.update(overrides)


update_config(globals(), CONFIG_FILE)
DB_STRUCTURE = importlib.import_module(DB_STRUCTURE)
REAL_DB_STRUCTURE = DB_STRUCTURE.REAL_DB_STRUCTURE


def merge_dicts(a, b):
    if a is None:
        return b
    elif b is None:
        return a

    assert type(a) == type(b) == dict, 'type mismatch!: {} != {}'.format(
        type(a),
        type(b),
    )

    # the database code relies on the ordering of elements, so ensure
    # that a consistent ordering, even on Python 3.5
    return collections.OrderedDict(
        (
            k,
            b[k] if k not in a
            else
            a[k] if k not in b
            else merge_dicts(a[k], b[k])
        )
        for k in itertools.chain(a, b)
    )


def load_db_extensions(exts=None):
    global DB_STRUCTURE, REAL_DB_STRUCTURE

    if not exts:
        return

    if isinstance(exts, str):
        with open(exts) as fp:
            exts = json.load(fp)

    DB_STRUCTURE.DATABASE_STRUCTURE = merge_dicts(
        DB_STRUCTURE.DATABASE_STRUCTURE,
        exts,
    )

    REAL_DB_STRUCTURE = DB_STRUCTURE.REAL_DB_STRUCTURE = merge_dicts(
        DB_STRUCTURE.REAL_DB_STRUCTURE,
        exts,
    )


load_db_extensions(os.getenv('DB_STRUCTURE_EXTENSIONS'))
