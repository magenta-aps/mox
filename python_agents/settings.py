"""Settings for the different MOX agents included in this bundle."""
AMQP_SERVER = 'localhost'

MOX_ADVIS_QUEUE = 'Advis'

OIOREST_SERVER = "https://moxtest.magenta-aps.dk"

# Public key of SAML IDP
SAML_IDP_CERTIFICATE = 'test_auth_data/idp-certificate.pem'

# Default system email
FROM_EMAIL = 'mox-advis@noreply.magenta.dk'
ADVIS_SUBJECT_PREFIX = '[MOX-ADVIS]'

# Log file
MOX_ADVIS_LOG_FILE = '/var/log/python_mox_agents/mox-advis.log'
