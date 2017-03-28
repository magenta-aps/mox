"""Settings for the different MOX agents included in this bundle."""
import os

DIR = os.path.dirname(__file__)

AMQP_SERVER = 'localhost'

MOX_ADVIS_QUEUE = 'Advis'
MOX_LOG_EXCHANGE = 'mox.log'
MOX_OBJECT_EXCHANGE = 'mox.rest'

IS_LOG_AUTHENTICATION_ENABLED = False

OIOREST_SERVER = "https://referencedata.dk"

# Public key of SAML IDP
SAML_IDP_CERTIFICATE = os.path.join(DIR, 'test_auth_data/idp-certificate.pem')

# Default system email
FROM_EMAIL = 'mox-advis@noreply.magenta.dk'
ADVIS_SUBJECT_PREFIX = '[MOX-ADVIS]'

# Log files
MOX_ADVIS_LOG_FILE = '/var/log/mox/mox-advis.log'
MOX_ELK_LOG_FILE = '/var/log/mox/mox-elk.log'
DO_LOG_TO_AMQP = True
