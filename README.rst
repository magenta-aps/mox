===============================================
MOX Messaging Service and Actual State Database
===============================================

Introduction
============

.. contents::
   :depth: 5

This project contains an implementation of the OIO object model, used
as a standard for data exchange by the Danish government, for use with
a MOX messaging queue.

You can find the current MOX specification here:

http://www.kl.dk/ImageVaultFiles/id_55874/cf_202/MOX_specifikation_version_0.PDF

As an example, you can find the Organisation hierarchy
here:

http://digitaliser.dk/resource/991439

In each installation of MOX, it is possible to only enable
some of the hierarchies, but we provide the following four OIO
hierarchies by default:

* *Klassifikation*
* *Sag*
* *Dokument*
* *Organisation*


On this documentation
---------------------

This README file is part of our documentation, and an HTML version can
be obtained by the following command in a command prompt::

    $ make -C doc

Note that this requires Sphinx to be installed — on Ubuntu or
Debian, this can be done with the following command::

    $ sudo apt install python-sphinx

If you're reading this on GitHub or ReadTheDocs, you're probably
seeing the HTML rendering. The official location for this
documentation is:

* http://mox.readthedocs.io/

Please note that as a convention, all shell commands have been
prefixed with a dollar-sign, or ``$``, representing a prompt. You
should exclude this when entering the command in your terminal.

Audience
--------

This is a technical guide. You are not expected to have a profound knowledge of
the system as such, but you do have to know your way in a Bash prompt — you 
should be able to change the Apache configuration and e.g. disable or change
the SSL certificate on your own.

System requirements
===================

LoRA currently supports Ubuntu 16.04 (Xenial).
We recommend running it on a VM with the following allocation:

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * -
     - CPU
     - Memory
     - Storage
     - Disk type
   * - Minimal
     - 1 core
     - 2 GB
     - 15 GB
     - any *(SSD or HD)*
   * - Test & development
     - 2 cores
     - 4 GB
     - 30 GB
     - SSD *(recommended)*
   * - Production
     - 4 cores
     - 8 GB
     - 60 GB
     - SSD

You should initially provision all the storage space you expect to use,
as adjusting it is somewhat cumbersome. By comparison, increasing or
decreasing CPU and memory is trivial.

Getting started
===============

To install the OIO REST API, run ``install.sh``::

  $ sudo apt-get install git
  $ git clone https://github.com/magenta-aps/mox
  $ cd mox
  $ ./install.sh

.. note::

   Using the built-in installer should be considered
   a "developer installation". Please note that it *will not* work
   on a machine with less than 1GB of RAM.

   In the current state of the installer,
   we recommend using it only on a newly installed system,
   preferrably in a dedicated container or VM.
   It is our intention to provide more flexible
   installation options in the near future.

The default location of the log directory is::

   /var/log/mox

The following log files are created:

 - Audit log: /var/log/mox/audit.log
 - OIO REST HTTP access log: /var/log/mox/oio_access.log
 - OIO REST HTTP error log: /var/log/mox/oio_error.log

Additionally, a directory for file uploads is created::

   # settings.py
   FILE_UPLOAD_FOLDER = getenv('FILE_UPLOAD_FOLDER', '/var/mox')


The oio rest api is installed as a service,
for more information, see the oio_rest.service.

By default the oio_rest service can be reached as follows::

   http://localhost:8080

Example::

   curl http://localhost:8080/organisation/bruger

.. note::
   In a production environment,
   it is recommended to bind the oio_rest service to a unix socket,
   then expose the socket using a HTTP proxy of your own choosing.

   (Recommended: Nginx or Apache)

   More on how to configure in the advanced configuration document.
   Link: ``Document is currently being written``


Configuration
-------------

Most configurable parameters of oio_rest can be injected with
environment variables, alternatively you may set the parameters
explicitly in the "settings.py" file.

(Please see $ROOT/oio_rest/settings.py)

As mentioned, most parameters are accessible.
If they are NOT set by you, we have provided sensible fallback values.

Example::

   # settings.py

   # DB (Postgres) settings
   DATABASE = getenv('DB_NAME', 'mox')
   DB_USER = getenv('DB_USER', 'mox')
   DB_PASSWORD = getenv('DB_PASS', 'mox')


The oio rest api is served using the wsgi server gunicorn.
The gunicorn server can be configured through the "guniconfig.py" file.

(Please see $ROOT/oio_rest/guniconfig.py)

Similar to the oio rest settings file,
gunicorn can be configured using environment variables: ::

   # guniconfig.py

   # Bind address (Can be either TCP or Unix socket)
   bind = env("GUNICORN_BIND_ADDRESS", '127.0.0.1:8080')


Components
==========

On a high level the MOX actual state database consists of three server
processes and several agents joining them together.

Server processes
----------------

PostgreSQL
    Database server providing the storage of the bi-temporal actual
    state database as well as validation and verification of the basic
    constraints.

Gunicorn
    WSGI server for the oio rest api.
    Ideally used with a frontend HTTP proxy in production.

RabbitMQ
    AMQP message broker providing interprocess communication between
    the various components.

Agents
------

Within the context of the Mox Messaging Service, agents are small
pieces of software which either listen on an AMQP queue and perform
operations on the incoming data, or expose certain operations as a web
service.

The default installation includes the following agents:

MoxDocumentDownload
    Web service for exporting actual state contents as Excel
    spreadsheets.

MoxDocumentUpload
    Web service for importing data from Excel spreadsheets into the
    actual state database.

MoxRestFrontend
    AMQP agent bridging the REST API.

MoxTabel
    AQMP worker agent MoxDocumentDownload & MoxDocumentUpload.

Authentication
==============

SAML token authentication is enabled by default. This requires that
you have access to a SAML Identity Provider (IdP) which provides a
Security Token Service (STS). We currently support two types:

* Active Directory Federation Services
* WSO2


Using Active Directory Federation Services
------------------------------------------

In order to use AD FS as the Security Token Service, you first need an
*endpoint* configured in ADFS. You should name this endpoint
corresponding to the designated name of the box running LoRA, for
example::

  https://lora.magenta.dk

As for the attributes to send, select the following:

=====================================  ====================
LDAP Attribute                         Outgoing Claim Type
=====================================  ====================
objectGUID                             PPID
User-Principal-Name                    NameID
Token-Groups (Unqualified Names)       Group
=====================================  ====================

Please note that you should configure AD FS to sign, but not encrypt,
its assertions.

Then configure the following fields in ``oio_rest/oio_rest/settings.py``:

=====================================  ====================
Setting                                Description
=====================================  ====================
``SAML_MOX_ENTITY_ID``                 In this case, “``https://lora.magenta-aps.dk``”.
``SAML_IDP_ENTITY_ID``                 The name of your ADFS.
``SAML_IDP_URL``                       The URL where your ADFS may be reached.
``SAML_IDP_TYPE``                      ``"adfs"``
``USE_SAML_AUTHENTICATION``            ``True``
``SAML_USER_ID_ATTIBUTE``              ``"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/privatepersonalidentifier"``
=====================================  ====================

You should now be able to test the basic configuration, and extract
the signing certificate::

  $ cd /path/to/mox
  $ ./auth.sh --cert-only
  User: user@domain
  Password: <enter password here>

Now save the results to a file, e.g. ``adfs-cert.pem``, and set that
as ``SAML_IDP_CERTIFICATE``. You may get an SSL error, in that case,
you should add your certificate authority to the system.
Alternatively, you can pass the ``--insecure`` option to ``auth.sh``
temporarily bypass the error.

Using WSO2 for testing
------------------------------------------

The open source identity provider `WSO2
<http://wso2.com/products/identity-server>`_ is useful for testing.
Download the binary and follow the instructions to run it.

In the folder ``wso2/`` you can find an example init file for running the
WSO2 Identity Server as a daemon.

To configure a STS, follow the instructions on
https://docs.wso2.com/display/IS500/Configuring+the+Identity+Server+to+Issue+Security+Tokens
(skip the part about Holder of Key).

Restart the WSO2 server! The STS endpoint simply did not work until I
restarted the WSO2 server.

Setting up users on the IDP
+++++++++++++++++++++++++++

This is for testing with the WSO2 Identity Server as described above -
we assume that this is not the configuration which the municipalities
want to use in a production setting.

Log in to the IDP with the credentials provided. The IDP could, e.g., be
located at https://moxtest.magenta-aps.dk:9443/.

To create a new user, enter the "Configure" tab and select "Users and
roles". Enter the user's first name, last name and email address.

**Important:** In the URL field, enter the user's (OIO) UUID. The URL
field is currently used to map between the IDP and the OIO's user
concept. If the UUID is not specified, it will not be possible to
authorize users correctly, nor will it be possible to make any changes
to the database.


OIO-REST SAML settings
++++++++++++++++++++++

The default IdP entity ID is called "localhost". If your IdP has a
different entity ID, you must change the SAML_IDP_ENTITY_ID setting
to reflect your IdP's entity ID.

For testing purposes, WSO2's IdP public certificate file is included in the
distribution.

When configuring the REST API to use your IdP, you must specify your
IdP's public certificate file by setting in settings.py::

    export SAML_IDP_CERTIFICATE=/path/to/idp_certificate.pem

In settings.py, SAML authentication can be turned off by setting::

    USE_SAML_AUTHENTICATION = False


Requesting a SAML token using the OIO REST service
--------------------------------------------------

The OIO REST service provides a convenience method for requesting a SAML
token in the correct base64-encoded gzipped format for use with the API.

Visit the following URL of the OIO REST server::

    http://localhost:8080/get-token

Alternatively, you can run the following command locally on the server::

  $ ./auth.sh -u <username> -p


You will be presented with a form with a username/password field.
Optionally, you can specify the STS address to use.
This will request a token from the STS service using the given
username and password. It will return the value that should be used for the
HTTP "Authorization" header. If it fails due to invalid username/password,
an error message will be returned.

This value can then be included in the HTTP "Authorization" header, like the
following::

    Authorization: <output of get-token>

For testing purposes, we recommend the browser extensions `Advanced
REST client`_ for Chrome or `REST Easy`_ for Firefox.

.. _Advanced REST client: https://chrome.google.com/webstore/detail/advanced-rest-client/hgmloofddffdnphfgcellkdfbfbjeloo
.. _REST Easy: https://addons.mozilla.org/da/firefox/addon/rest-easy/

Requesting a SAML token manually
--------------------------------

.. note::
    
    This section only applies covers using the *WSO2* IdP.

Although the Java MOX agent does this automatically, it can be useful
to request a SAML token manually, for testing purposes.

To request a SAML token, it is useful to use SoapUI.

Download `SoapUI <http://www.soapui.org/>`_ and import the project
provided in ``oio_rest/test_auth_data/soapui-saml2-sts-request.xml``.

Navigate to and double-click on::

    "sts" -> "wso2carbon-stsSoap11Binding" -> "Issue token - SAML 2.0"

Note: The value of ``<a:Address>`` element in ``<wsp:AppliesTo>`` must match your
``SAML_MOX_ENTITY_ID`` setting. Change as needed.

The project assumes you are running the IdP server on https://localhost:9443/
(the default).

Execute the SOAP request. You can copy the response by clicking on the
"Raw" tab in the right side of the window and then selecting all, and
copying to the clipboard. Paste the response, making sure that the
original whitespace/indentation is preserved. Remove all elements/text
surrounding the ``<saml2:Assertion>..</saml2:Assertion>`` tag. Save to a
file, e.g. /my/saml/assertion.xml.

After requesting a SAML token, to make a REST request using the SAML token,
you need to pass in an HTTP Authorization header of a specific format::

    Authorization: saml-gzipped <base64-encoded gzip-compressed SAML assertion>

A script has been included to generate this HTTP header from a SAML token
XML file. This file must only contain the ``<saml2:Assertion>`` element.

To run it::

    $ python oio_rest/oio_rest/utils/encode_token.py /my/saml/assertion.xml

The output of this script can be used in a curl request by adding the
parameter -H, e.g.::

    $ curl -H "Authorization saml-gzipped eJy9V1................." ...

to the curl request. 

Alternately, if using bash shell::

    $ curl -H "$(python oio_rest/oio_rest/utils/encode_token.py" /my/saml/assertion.xml) ...


Licensing
=========

The MOX messaging queue, including the ActualState database, as found
in this project is free software. You are entitled to use, study,
modify and share it under the provisions of `Version 2.0 of the
Mozilla Public License <https://www.mozilla.org/MPL/2.0/>`_ as
specified in the ``LICENSE`` file.

This software was developed by `Magenta ApS <http://www.magenta.dk>`_. For
feedback, feel  free to open an issue in the `GitHub repository
<https://github.com/magenta-aps/mox>`_.

