"""Settings for the different MOX agents included in this bundle."""
import os

DIR = os.path.dirname(__file__)

AMQP_SERVER = 'localhost'

MOX_ADVIS_QUEUE = 'Advis'

OIOREST_SERVER = "https://referencedata.dk"

# Public key of SAML IDP
SAML_IDP_CERTIFICATE = os.path.join(DIR, 'test_auth_data/idp-certificate.pem')

# Default system email
FROM_EMAIL = 'mox-advis@noreply.magenta.dk'
ADVIS_SUBJECT_PREFIX = '[MOX-ADVIS]'

# Log file
MOX_ADVIS_LOG_FILE = '/var/log/python_mox_agents/mox-advis.log'
