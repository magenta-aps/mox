# -*- python -*-

from os import getenv


# Base url
BASE_URL = getenv('BASE_URL', '')

# DB (Postgres) settings
DATABASE = getenv('DB_NAME', 'mox')
DB_USER = getenv('DB_USER', 'mox')
DB_PASSWORD = getenv('DB_PASS', 'mox')

# Per-process limits on the amount of database connections. Setting
# the minimum to a non-zero value ensures that the webapp opens this
# amount at load, failing if the database isn't available.
DB_MIN_CONNECTIONS = int(getenv('DB_MIN_CONNECTIONS', '0'))
DB_MAX_CONNECTIONS = int(getenv('DB_MAX_CONNECTIONS', '10'))

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
