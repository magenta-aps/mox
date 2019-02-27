========
Settings
========

Most configurable parameters of ``oio_rest`` can be injected with environment
variables, alternatively you may set the parameters in a file.

Environment variables overwrites default values. The settings file overwrites
both default values `and environment variables`.

.. py:data:: CONFIG_FILE

   Default: ``None``

   Setting the environment variable :data:`CONFIG_FILE` to a a path to a JSON
   file containing a dict of ``"<setting>": <value>`` pairs will load the
   settings specified in the file.

   The settings from the file have precedens over any environment variables and
   will overwrite their values.


.. py:data:: BASE_URL

   Default: ``""`` (Empty string)

   .. todo::

      Fill out this section.


Database
--------

PostgreSQL

.. todo::

      Fill out this section.

.. py:data:: DB_HOST

   Default: ``"localhost"``

.. py:data:: DB_PORT

   Default: ``0``

.. py:data:: DB_USER

   Default: ``"mox"``

.. py:data:: DB_PASSWORD

   Default: ``"mox"``


# name of database, should be changed to use `DB_` convention.

.. py:data:: DATABASE

   Default: ``"mox"``


# Per-process limits on the amount of database connections. Setting the minimum
# to a non-zero value ensures that the webapp opens this amount at load,
# failing if the database isn't available.

.. py:data:: DB_MIN_CONNECTIONS

   Default: ``0``

.. py:data:: DB_MAX_CONNECTIONS

   Default: ``10``

.. py:data:: DB_STRUCTURE

   Default: ``"oio_rest.db.db_structure"``

File upload
-----------

.. todo::

      Fix this section.

# This is where file uploads are stored. It must be readable and writable by
# the mox user, running the REST API server. This is used in the Dokument
# hierarchy.

.. py:data:: FILE_UPLOAD_FOLDER

   Default: ``"/var/mox"``

SAML
----

.. todo::

      Fix this section.

# The Endpoint specified in the AppliesTo element of the STS request
# This will be used to verify the Audience of the SAML Assertion

.. py:data:: SAML_MOX_ENTITY_ID

   Default: ``"https://saml.local'"``



# The Entity ID of the IdP. Used to verify the token Issuer --
# specified in AD FS as the Federation Service identifier.
# Example: 'http://fs.contoso.com/adfs/services/trust'

.. py:data:: SAML_IDP_ENTITY_ID

   Default: ``"localhost"``



# The URL on which to access the SAML IdP.
# Example: 'https://fs.contoso.com/adfs/services/trust/13/UsernameMixed'

.. py:data:: SAML_IDP_URL

   Default: ``"https://localhost:9443/services/wso2carbon-sts.wso2carbon-stsHttpsEndpoint"``

# We currently support authentication against 'wso2' and 'adfs'

.. py:data:: SAML_IDP_TYPE

   Default: ``"wso2"``



# The public certificate file of the IdP, in PEM-format.

.. py:data:: SAML_IDP_CERTIFICATE

   Default: ``"test_auth_data/idp-certificate.pem"``



# Whether to enable SAML authentication

.. py:data:: USE_SAML_AUTHENTICATION

   Default: ``False``



# SAML user ID attribute -- default is for WSO2
# Example:
#   http://schemas.xmlsoap.org
#       /ws/2005/05/identity/claims/privatepersonalidentifier

.. py:data:: SAML_USER_ID_ATTIBUTE

   Default: ``"http://wso2.org/claims/url"``

Second section with SAML
++++++++++++++++++++++++

.. todo::

      Fix this section. Merge or find better name.

.. py:data:: SAML_IDP_METADATA_URL

   Default: ``"https://172.16.20.100/simplesaml/saml2/idp/metadata.php"``

.. py:data:: SAML_IDP_INSECURE

   Default: ``False``

.. py:data:: SAML_REQUESTS_SIGNED

   Default: ``False``

.. py:data:: SAML_KEY_FILE

   Default: ``None``

.. py:data:: SAML_CERT_FILE

   Default: ``None``

.. py:data:: SAML_AUTH_ENABLE

   Default: ``False``

Authorization
-------------

.. todo::

      Fix this section. Maby merge with SAML.

# Whether authorization is enabled.

# If not, the restrictions module is not called.

.. py:data:: DO_ENABLE_RESTRICTIONS

   Default: ``False``


# The module which implements the authorization restrictions.
# Must be present in sys.path.

.. py:data:: AUTH_RESTRICTION_MODULE

   Default: ``"oio_rest.auth.wso_restrictions"``



# The name of the function which retrieves the restrictions.
# Must be present in AUTH_RESTRICTION_MODULE and have the correct signature.

.. py:data:: AUTH_RESTRICTION_FUNCTION

   Default: ``"get_auth_restrictions"``



Log AMQP
--------

.. todo::

      Fix this section.

.. py:data:: LOG_AMQP_SERVER

   Default: ``"localhost"``

.. py:data:: MOX_LOG_EXCHANGE

   Default: ``"mox.log"``

.. py:data:: MOX_LOG_QUEUE

   Default: ``"mox.log_queue"``

.. py:data:: LOG_IGNORED_SERVICES

   Default: ``['Log', ]``

   .. warning::
      No ENV variable


.. py:data:: AUDIT_LOG_FILE

   Default: ``"/var/log/mox/audit.log"``


Session
-------

.. todo::

      Fix this section.

.. py:data:: SQLALCHEMY_DATABASE_URI

   Default: ``"postgresql://sessions:sessions@127.0.0.1/sessions"``

.. py:data:: SESSION_PERMANENT

   Default: ``True``

.. py:data:: PERMANENT_SESSION_LIFETIME

   Default: ``3600``
