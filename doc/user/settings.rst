========
Settings
========

Most configurable parameters of ``oio_rest`` can be injected with environment
variables. Alternatively, you may set the parameters in a file.

Environment variables overwrite default values. The settings file overwrites
both default values `and environment variables`.

.. py:data:: CONFIG_FILE

   Default: ``None``

   Setting the environment variable :data:`CONFIG_FILE` to a path to a JSON
   file containing a dictionary of ``"<setting>": <value>`` pairs will load the
   settings specified in the file.

   The settings from the file have precedence over any environment variables and
   will overwrite their values.


.. py:data:: BASE_URL

   Default: ``""`` (Empty string)

   Prefix for all relative URLs. A value of ``"/MyOIO"`` will give API endpoints
   such as ``http://example.com/MyOIO/organisation/organisationenhed``.


Database
========

PostgreSQL


.. py:data:: DB_HOST

   Default: ``"localhost"``

   The host to use when connecting to the database.

.. py:data:: DB_PORT

   Default: ``None``

   The port to use when connecting to the database specified in :data:`DB_HOST`.

.. py:data:: DB_USER

   Default: ``"mox"``

   The username to use when connecting to the database.

.. py:data:: DB_PASSWORD

   Default: ``"mox"``

   The password to use when connecting to the database.

.. py:data:: DATABASE

   Default: ``"mox"``

   The name of the database to use.


.. py:data:: DB_MIN_CONNECTIONS

   Default: ``0``

   Per-process lower limit on the amount of database connections. Setting it to
   a non-zero value ensures that the web application opens this amount at load,
   failing if the database isn't available.

.. py:data:: DB_MAX_CONNECTIONS

   Default: ``10``

   Per-process upper limit on the amount of database connections.

.. py:data:: DB_STRUCTURE

   Default: ``"oio_rest.db.db_structure"``

   The structure of the whole database. Overwrite this if you want to extend the
   database with additional fields on the objects.

File upload
===========

.. py:data:: FILE_UPLOAD_FOLDER

   Default: ``"/var/mox"``

   This path is where file uploads are stored. It must be readable and writeable
   by the system user running the REST API server. This is used in the Dokument
   hierarchy.



Audit log
=========

An audit log is published as AMQP messages and written to a dedicated queue.

.. py:data:: LOG_AMQP_SERVER

   Default: ``""``

   The AMQP server used to publish the audit log. If empty, audit
   logging is off.

   Not to be confused by the AMQP service used by
   :file:`/python_agents/notification_service/notify_to_amqp_service.py`.

.. py:data:: MOX_LOG_EXCHANGE

   Default: ``"mox.log"``

   The AMQP exchange used for the audit log.

.. py:data:: MOX_LOG_QUEUE

   Default: ``"mox.log_queue"``

   The AMQP queue used for the audit log.


.. _auth-settings:

Authentication
==============
.. todo::

      Fix this whole section as part of #25911.

LoRa has two independent ways to use SAML. An older one from the file
:file:`mox/oio_rest/oio_rest/auth/saml2.py` and a newer one from the package
`flask_saml_sso <https://github.com/magenta-aps/flask_saml_sso>`_. Only use one
of them at a time. They are both disabled by default. For an overview of how
:file:`mox/oio_rest/oio_rest/auth/saml2.py` works, see :ref:`auth`.

SAML from :file:`mox/oio_rest/oio_rest/auth/saml2.py`
------------------------------------------------------

.. py:data:: USE_SAML_AUTHENTICATION

   Default: ``False``

   Whether to enable SAML authentication from :file:`mox/oio_rest/oio_rest/auth/saml2.py`.

.. py:data:: SAML_MOX_ENTITY_ID

   Default: ``"https://saml.local'"``

   The Endpoint specified in the ``AppliesTo`` element of the STS request. This
   will be used to verify the Audience of the SAML Assertion.


.. py:data:: SAML_IDP_ENTITY_ID

   Default: ``"localhost"``

   The Entity ID of the IdP. Used to verify the token Issuer specified in AD FS
   as the Federation Service identifier.

   Example: ``"http://fs.contoso.com/adfs/services/trust"``


.. py:data:: SAML_IDP_URL

   Default: ``"https://localhost:9443/services/wso2carbon-sts.wso2carbon-stsHttpsEndpoint"``

   The URL on which to access the SAML IdP.

   Example: ``"https://fs.contoso.com/adfs/services/trust/13/UsernameMixed"``


.. py:data:: SAML_IDP_TYPE

   Default: ``"wso2"``

   We currently support authentication against ``wso2`` and ``adfs``.


.. py:data:: SAML_IDP_CERTIFICATE

   Default: ``"test_auth_data/idp-certificate.pem"``

   The public certificate file of the IdP, in PEM-format.


.. py:data:: SAML_USER_ID_ATTIBUTE

   Default: ``"http://wso2.org/claims/url"``

   SAML user ID attribute. Default is for WSO2

   Example:
   ``"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/privatepersonalidentifier"``



SAML from ``flask_saml_sso``
----------------------------

Refer to the readme for `flask_saml_sso
<https://github.com/magenta-aps/flask_saml_sso>`_ for these settings.


.. py:data:: SAML_AUTH_ENABLE

   Default: ``False``

   Enables SAML authentication from ``flask_saml_sso``.

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


.. py:data:: SQLALCHEMY_DATABASE_URI

   Default: ``"postgresql://sessions:sessions@127.0.0.1/sessions"``


.. py:data:: SESSION_PERMANENT

   Default: ``True``


.. py:data:: PERMANENT_SESSION_LIFETIME

   Default: ``3600``


Restrictions
============

.. todo::

       When writing authentication documentation #25911, include a section on
       restrictions and link to it from here.

.. py:data:: DO_ENABLE_RESTRICTIONS

   Default: ``False``

   Whether authorization is enabled and restrictions can be used. If not, the
   :data:`AUTH_RESTRICTION_MODULE` is not called.

.. py:data:: AUTH_RESTRICTION_MODULE

   Default: ``"oio_rest.auth.wso_restrictions"``

   The module which implements the authorization restrictions.
   Must be present in ``sys.path``.


.. py:data:: AUTH_RESTRICTION_FUNCTION

   Default: ``"get_auth_restrictions"``

   The name of the function which retrieves the restrictions. Must be present in
   :data:`AUTH_RESTRICTION_MODULE` and have the correct signature.
