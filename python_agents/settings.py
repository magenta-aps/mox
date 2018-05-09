"""Settings for the different MOX agents included in this bundle."""
import os

DIR = os.path.dirname(__file__)

# Settings
# Use environment variable or fallback value

# System settings
AMQP_SERVER = os.getenv('MOX_AMQP_HOST', 'localhost')

# Agent settings
MOX_ADVIS_QUEUE = os.getenv('MOX_ADVIS_QUEUE', 'Advis')
MOX_LOG_EXCHANGE = os.getenv('MOX_LOG_EXCHANGE', 'mox.log')
MOX_OBJECT_EXCHANGE = os.getenv('MOX_OBJECT_EXCHANGE', 'mox.rest')

IS_LOG_AUTHENTICATION_ENABLED = os.getenv('MOX_LOG_AUTHENTICATION_ENABLED', False)

OIOREST_SERVER = os.getenv('MOX_OIO_REST_URI', 'https://localhost')

# Default system email
FROM_EMAIL = env('MOX_EMAIL_REPLY_ADDRESS', 'mox-advis@noreply.magenta.dk')
ADVIS_SUBJECT_PREFIX = '[MOX-ADVIS]'

# Log files
MOX_ADVIS_LOG_FILE = os.getenv('MOX_ADVIS_LOG_FILE', '/var/log/mox/mox-advis.log')
MOX_ELK_LOG_FILE = os.getenv('MOX_ELK_LOG_FILE', '/var/log/mox/mox-elk.log')
DO_LOG_TO_AMQP = os.getenv('MOX_ENABLE_LOG_TO_AMQP', True)

# Saml settings
SAML_IDP_ENTITY_ID = os.getenv('MOX_SAML_IDP_ENTITY_ID', 'localhost')
SAML_MOX_ENTITY_ID = os.getenv('MOX_SAML_MOX_ENTITY_ID', 'https://localhost')

# Legacy
TEST_PUBLIC_KEY = os.path.join(DIR, 'test_auth_data/idp-certificate.pem')
SAML_IDP_CERTIFICATE = os.getenv('MOX_SAML_IDP_CERTIFICATE', TEST_PUBLIC_KEY)

# Logstash settings
MOX_LOGSTASH_URI = os.getenv('MOX_LOGSTASH_URI', 'http://127.0.0.1:42998')
MOX_LOGSTASH_USER = os.getenv('MOX_LOGSTASH_USER', 'mox_logstash_user')
MOX_LOGSTASH_PASS = os.getenv('MOX_LOGSTASH_PASS', 'secretlogstashpassword')