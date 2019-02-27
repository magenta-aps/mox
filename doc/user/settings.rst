========
Settings
========


.. py:data:: CONFIG_FILE = os.getenv('OIO_REST_CONFIG_FILE', None)

.. py:data:: BASE_URL = os.getenv('BASE_URL', '')



# Database (PostgreSQL) settings

.. py:data:: DB_HOST = os.getenv('DB_HOST', "localhost")

.. py:data:: DB_PORT = int(os.getenv('DB_PORT', '0')) or None

.. py:data:: DB_USER = os.getenv('DB_USER', "mox")

.. py:data:: DB_PASSWORD = os.getenv('DB_PASSWORD', "mox")



# name of database, should be changed to use `DB_` convention.

.. py:data:: DATABASE = os.getenv('DB_NAME' ,"mox")



# Per-process limits on the amount of database connections. Setting the minimum
# to a non-zero value ensures that the webapp opens this amount at load,
# failing if the database isn't available.

.. py:data:: DB_MIN_CONNECTIONS = int(os.getenv('DB_MIN_CONNECTIONS', '0'))

.. py:data:: DB_MAX_CONNECTIONS = int(os.getenv('DB_MAX_CONNECTIONS', '10'))

.. py:data:: DB_STRUCTURE = os.getenv('DB_STRUCTURE', 'oio_rest.db.db_structure')



# This is where file uploads are stored. It must be readable and writable by
# the mox user, running the REST API server. This is used in the Dokument
# hierarchy.

.. py:data:: FILE_UPLOAD_FOLDER = os.getenv('FILE_UPLOAD_FOLDER', '/var/mox')



# The Endpoint specified in the AppliesTo element of the STS request
# This will be used to verify the Audience of the SAML Assertion

.. py:data:: SAML_MOX_ENTITY_ID = os.getenv('SAML_MOX_ENTITY_ID', 'https://saml.local')



# The Entity ID of the IdP. Used to verify the token Issuer --
# specified in AD FS as the Federation Service identifier.
# Example: 'http://fs.contoso.com/adfs/services/trust'

.. py:data:: SAML_IDP_ENTITY_ID = os.getenv('SAML_IDP_ENTITY_ID', 'localhost')



# The URL on which to access the SAML IdP.
# Example: 'https://fs.contoso.com/adfs/services/trust/13/UsernameMixed'

.. py:data:: SAML_IDP_URL = os.getenv('SAML_IDP_URL', 'https://localhost:9443/services/wso2carbon-sts.wso2carbon-stsHttpsEndpoint')


# We currently support authentication against 'wso2' and 'adfs'

.. py:data:: SAML_IDP_TYPE = os.getenv('SAML_IDP_TYPE', 'wso2')



# The public certificate file of the IdP, in PEM-format.

.. py:data:: SAML_IDP_CERTIFICATE = os.getenv('SAML_IDP_CERTIFICATE', 'test_auth_data/idp-certificate.pem')



# Whether to enable SAML authentication
.. py:data:: USE_SAML_AUTHENTICATION = os.getenv('USE_SAML_AUTHENTICATION', False)



# SAML user ID attribute -- default is for WSO2
# Example:
#   http://schemas.xmlsoap.org
#       /ws/2005/05/identity/claims/privatepersonalidentifier

.. py:data:: SAML_USER_ID_ATTIBUTE = os.getenv('SAML_USER_ID_ATTIBUTE', 'http://wso2.org/claims/url')



# Whether authorization is enabled.

# If not, the restrictions module is not called.

.. py:data:: DO_ENABLE_RESTRICTIONS = os.getenv('DO_ENABLE_RESTRICTIONS', False)


# The module which implements the authorization restrictions.
# Must be present in sys.path.

.. py:data:: AUTH_RESTRICTION_MODULE = os.getenv('AUTH_RESTRICTION_MODULE', 'oio_rest.auth.wso_restrictions',)



# The name of the function which retrieves the restrictions.
# Must be present in AUTH_RESTRICTION_MODULE and have the correct signature.

.. py:data:: AUTH_RESTRICTION_FUNCTION = os.getenv('AUTH_RESTRICTION_FUNCTION','get_auth_restrictions',)



# Log AMQP settings

.. py:data:: LOG_AMQP_SERVER = os.getenv('LOG_AMQP_SERVER', 'localhost')

.. py:data:: MOX_LOG_EXCHANGE = os.getenv('MOX_LOG_EXCHANGE', 'mox.log')

.. py:data:: MOX_LOG_QUEUE = os.getenv('MOX_LOG_QUEUE', 'mox.log_queue')



.. py:data:: LOG_IGNORED_SERVICES = ['Log', ]



.. py:data:: AUDIT_LOG_FILE = os.getenv('AUDIT_LOG_FILE', '/var/log/mox/audit.log')



.. py:data:: SAML_IDP_METADATA_URL = os.getenv('SAML_IDP_METADATA_URL', 'https://172.16.20.100/simplesaml/saml2/idp/metadata.php')

.. py:data:: SAML_IDP_INSECURE = os.getenv('SAML_IDP_INSECURE', False)

.. py:data:: SAML_REQUESTS_SIGNED = os.getenv('SAML_REQUESTS_SIGNED', False)

.. py:data:: SAML_KEY_FILE = os.getenv('SAML_KEY_FILE', None)

.. py:data:: SAML_CERT_FILE = os.getenv('SAML_CERT_FILE', None)

.. py:data:: SAML_AUTH_ENABLE = os.getenv('SAML_AUTH_ENABLE', False)



.. py:data:: SQLALCHEMY_DATABASE_URI = os.getenv('SQLALCHEMY_DATABASE_URI', "postgresql://sessions:sessions@127.0.0.1/sessions",)

.. py:data:: SESSION_PERMANENT = os.getenv('SESSION_PERMANENT', True)

.. py:data:: PERMANENT_SESSION_LIFETIME = os.getenv('PERMANENT_SESSION_LIFETIME', 3600)
