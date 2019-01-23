# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


# -*- python -*-

from importlib import import_module
from os import getenv

import json

CONFIG_FILE = getenv('OIO_REST_CONFIG_FILE', None)

# Base url
BASE_URL = getenv('BASE_URL', '')

# DB (Postgres) settings
DB_HOST = "localhost"
DB_PORT = None
DB_USER = "mox"
DB_PASSWORD = "mox"

# TODO: Database name parameter should be streamlined with other DB parameters
DATABASE = "mox"

# Per-process limits on the amount of database connections. Setting
# the minimum to a non-zero value ensures that the webapp opens this
# amount at load, failing if the database isn't available.
DB_MIN_CONNECTIONS = int(getenv('DB_MIN_CONNECTIONS', '0'))
DB_MAX_CONNECTIONS = int(getenv('DB_MAX_CONNECTIONS', '10'))

DB_STRUCTURE = import_module(getenv('DB_STRUCTURE',
                                    'oio_rest.db.db_structure'))
REAL_DB_STRUCTURE = DB_STRUCTURE.REAL_DB_STRUCTURE

# This is where file uploads are stored. It must be readable and writable by
# the mox user, running the REST API server. This is used in the Dokument
# hierarchy.
FILE_UPLOAD_FOLDER = getenv('FILE_UPLOAD_FOLDER', '/var/mox')

# The Endpoint specified in the AppliesTo element of the STS request
# This will be used to verify the Audience of the SAML Assertion
SAML_MOX_ENTITY_ID = getenv('SAML_MOX_ENTITY_ID', 'https://saml.local')

# The Entity ID of the IdP. Used to verify the token Issuer --
# specified in AD FS as the Federation Service identifier.
# Example: 'http://fs.contoso.com/adfs/services/trust'
SAML_IDP_ENTITY_ID = getenv('SAML_IDP_ENTITY_ID', 'localhost')

# The URL on which to access the SAML IdP.
# Example: 'https://fs.contoso.com/adfs/services/trust/13/UsernameMixed'
SAML_IDP_URL = getenv(
    'SAML_IDP_URL',
    'https://localhost:9443/services/wso2carbon-sts.wso2carbon-stsHttpsEndpoint'
)

# We currently support authentication against 'wso2' and 'adfs'
SAML_IDP_TYPE = getenv('SAML_IDP_TYPE', 'wso2')

# The public certificate file of the IdP, in PEM-format.
SAML_IDP_CERTIFICATE = getenv(
    'SAML_IDP_CERTIFICATE',
    'test_auth_data/idp-certificate.pem'
)

# Whether to enable SAML authentication
USE_SAML_AUTHENTICATION = getenv('USE_SAML_AUTHENTICATION', False)

# SAML user ID attribute -- default is for WSO2
# Example:
#   http://schemas.xmlsoap.org
#       /ws/2005/05/identity/claims/privatepersonalidentifier
SAML_USER_ID_ATTIBUTE = getenv(
    'SAML_USER_ID_ATTIBUTE',
    'http://wso2.org/claims/url'
)

# Whether authorization is enabled
# if not, the restrictions module is not called.
DO_ENABLE_RESTRICTIONS = getenv('DO_ENABLE_RESTRICTIONS', False)

# The module which implements the authorization restrictions.
# Must be present in sys.path.
AUTH_RESTRICTION_MODULE = getenv(
    'AUTH_RESTRICTION_MODULE',
    'oio_rest.auth.wso_restrictions'
)

# The name of the function which retrieves the restrictions.
# Must be present in AUTH_RESTRICTION_MODULE and have the correct signature.
AUTH_RESTRICTION_FUNCTION = getenv(
    'AUTH_RESTRICTION_FUNCTION',
    'get_auth_restrictions'
)

# Log AMQP settings
LOG_AMQP_SERVER = getenv('LOG_AMQP_SERVER', 'localhost')
MOX_LOG_EXCHANGE = getenv('MOX_LOG_EXCHANGE', 'mox.log')
MOX_LOG_QUEUE = getenv('MOX_LOG_QUEUE', 'mox.log_queue')

# Ignore services
LOG_IGNORED_SERVICES = ['Log', ]

# Log files
AUDIT_LOG_FILE = getenv('AUDIT_LOG_FILE', '/var/log/mox/audit.log')

SAML_IDP_METADATA_URL = getenv(
    'SAML_IDP_METADATA_URL',
    'https://172.16.20.100/simplesaml/saml2/idp/metadata.php'
)
SAML_IDP_INSECURE = getenv('SAML_IDP_INSECURE', False)
SAML_REQUESTS_SIGNED = getenv('SAML_REQUESTS_SIGNED', False)
SAML_KEY_FILE = getenv('SAML_KEY_FILE', None)
SAML_CERT_FILE = getenv('SAML_CERT_FILE', None)
SAML_AUTH_ENABLE = getenv('SAML_AUTH_ENABLE', False)

SQLALCHEMY_DATABASE_URI = getenv(
    'SQLALCHEMY_DATABASE_URI',
    "postgresql://sessions:sessions@127.0.0.1/sessions"
)
SESSION_PERMANENT = getenv('SESSION_PERMANENT', True)
PERMANENT_SESSION_LIFETIME = getenv('PERMANENT_SESSION_LIFETIME', 3600)


def update_config(mapping, config_path):
    """load the JSON configuration at the given path """
    if not config_path:
        return

    try:
        with open(config_path) as fp:
            overrides = json.load(fp)

        for key in overrides.keys():
            mapping[key] = overrides[key]

    except IOError:
        print('Unable to read config {}'.format(config_path))
        pass


update_config(globals(), CONFIG_FILE)
