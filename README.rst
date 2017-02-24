Mox Messaging Service and Actual State Database
===============================================

.. contents:: `Table of contents`
   :depth: 5

This project contains an implementation (in PostgreSQL) of the OIO object
model, used as a standard for data exchange by the Danish government, for use
with a MOX messaging queue.

You can find the current MOX specification here:

http://www.kl.dk/ImageVaultFiles/id_55874/cf_202/MOX_specifikation_version_0.PDF

As an example, you can find the Organisation hierarchy
here:

http://digitaliser.dk/resource/991439/artefact/Informations-+og+meddelelsesmodeller+for+Organisation+%5bvs.+1.1%5d.pdf

This version of the system implements four OIO hierarchies, namely
Klassifikation, Sag, Dokument and Organisation. In each installation of
the service, it is possible to only enable some of the hierarchies.


On this documentation
---------------------

This README file is a reStructuredText document, and an HTML version can
be obtained by running the command ::

    rst2html README.rst README.html

in a command prompt. Note that this requires Python Docutils to be
installed - on Ubuntu or Debian, this can be done with the following
command: ::

    sudo apt-get install python-docutils

If you're reading this on Github, you're probably seeing the HTML
rendering.

Audience
--------

This is a technical guide. You are not expected to have a profound knowledge of
the system as such, but you do have to know your way in a Bash prompt - you 
should be able to change the Apache configuration and e.g. disable or change
the SSL certificate on your own.

Getting started
===============

Configuration
-------------

The file ``db/config.sh`` contains configuration for the database, such
as which username/password to use to connect to the database, and which
database name to use.

To setup the database to send notifications to an AMQP message exchange,
the database must know how to connect to the AMQP server. The defaults
assume you have a local AMQP server and use the guest user. However,
these can be changed in ``db/config.sh`` prior to performing
installation.

The file ``oio_rest/oio_rest/settings.py`` contains configuration for
the generation of the database structure and the REST API. Set the
DATABASE, DB_USER and DB_PASSWORD settings according to what you have
chosen in ``db/config.sh``.

The FILE_UPLOAD_FOLDER setting allows you to change where the database
stores its files (used for storing the contents of binary files in the
Dokument hierarchy). The default is i``/var/mox``, and this is
automatically created by the install script.

There are some other settings that can be changed, and there should be
comments describing their purpose, or they are described in another
section of this document.

Installing
----------

To install the OIO REST API, run ``install.sh``

By default, you will be prompted to reinstall the python virtualenv
if it already exists, and reinstall/overwrite the database
if it already exists.

To always answer yes to these questions, pass the ``-y`` parameter.

Run ``install.sh -h`` for a list of options.

**NOTE:** PostgreSQL 9.3 or later is required. If PostgreSQL is not installed
on your system already, it will be during installation.

To run the API for testing or development purposes, run: ::

    oio_rest/oio_api.sh 

Then, go to http://localhost:5000/site-map to see a map of all available
URLs, assuming you're running this on your local machine.

The install.sh script creates an Apache VirtualHost for oio rest and 
MoxDocumentUpload.

To run the OIO Rest Mox Agent (the one listening for messages and
relaying them onwards to the REST interface), run: ::

    agents/MoxRestFrontend/moxrestfrontend.sh

**NOTE:** You can start the agent in the background by running: ::

    sudo service moxrestfrontend start

To test sending messages through the agent, run: ::

    ./test.sh

**NOTE:** The install script does not set up an IDP for SAML authentication,
which is enabled by default. If you need to test without SAML authentication, 
you will need to turn it off as described below. 

To request a token for the username from the IdP and output it in
base64-encoded gzipped format, run: ::

    ./auth.sh -u <username> -p

Insert your username in the command argument. You will be prompted to enter
a password.

If SAML authentication is turned on (i.e., if the parameter
``USE_SAML_AUTHENTICATION`` in ``oio_rest/oio_rest/settings.py`` is
`True`), the IDP must be configured correctly - see the corresponding
sections below for instruction on how to do this.


Quick install
-------------

These commands should get you up and running quickly on a machine with a 
completely new Ubuntu 14.04 Server Edition: ::

    sudo apt-get install git
    cd /srv
    sudo git clone https://github.com/magenta-aps/mox
    sudo chown -R <username>:<username> mox/
    cd mox
    ./install.sh

**Note:** The <username> must belong to the sudo user you're using for the
installation. We recommend creating a dedicated "mox" user and stripping its
sudo rights when everything works.

**Note:** This will install the system in ``srv/mox``. It is of course
possible to install in any other location, but we do not recommend this 
for a quick install as it means a lot of configuration files need to be 
changed. In a later version, the user will be prompted for the location and 
the configuration will be generated accordingly.
to the location desired by the users.

**Note:** All commands, e.g. ``./test.sh``, are assumed to be issued from the
installation root directory, by default ``/srv/mox``.

Quick test
----------

Make sure the parameters ``USE_SAML_AUTHENTICATION`` in 
``oio_rest/oio_rest/settings.py`` is `False`.

Make sure the parameter ``moxrestfrontend.rest.host`` in
``agents/MoxRestFrontend/moxrestfrontend.conf`` is set to
`http://localhost:5000`.

Start the (AMQP) MOX REST frontend agent: ::

    sudo service moxrestfrontend start

Start the REST API: ::

    oio_rest/oio_api.sh

Run the tests: ::

    ./test.sh

This should give you a lot of output like this: ::

    Deleting bruger, uuid: 1e874f85-07e5-40e5-81ed-42f21fc3fc9e
    Getting authtoken
    127.0.0.1 - - [27/Apr/2016 15:55:09] "DELETE /organisation/bruger/1e874f85-07e5-40e5-81ed-42f21fc3fc9e HTTP/1.1" 200 -
    Delete succeeded

**Note:** Currently, some of the tests will give the notice: "Result differs
from the expected". This is due to a bug in the tests, i.e. you should not
worry about this - if you see output as described above, the system is working.

For more advanced test or production setup, please study the rest of this 
README and follow your organization's best practices.



Authentication
==========================================

SAML token authentication is enabled by default. This requires that
you have access to a SAML Identity Provider (IdP) which provides a
Security Token Service (STS). We currently support two types:

* Active Directory Federation Services
* WSO2_

.. _WSO2: http://wso2.com


Using Active Directory Federation Services
------------------------------------------

In order to use AD FS as the Security Token Service, you first need an
*endpoint* configured in ADFS. You should name this endpoint
corresponding to the designated name of the box running LoRA, for
example::

  https://lora.magenta-aps.dk

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

Setting up a WSO2 IdP with STS for testing
------------------------------------------

You need a STS (Security Token Service) running on your IdP.
An open-source IdP is available from http://wso2.com/products/identity-server/
and is useful for testing. Download the binary, and follow the instructions
to run it.

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
IdP's public certificate file by setting in settings.py: ::

    SAML_IDP_CERTIFICATE = '/my/idp/certificate.pem'

In settings.py, SAML authentication can be turned off by setting: ::

    USE_SAML_AUTHENTICATION = False


Requesting a SAML token using the OIO REST service
--------------------------------------------------

The OIO REST service provides a convenience method for requesting a SAML
token in the correct base64-encoded gzipped format for use with the API.

Visit the following URL of the OIO REST server, e.g. ::

    http://localhost:5000/get-token


You will be presented with a form with a username/password field.
Optionally, you can specify the STS address to use.
This will request a token from the STS service using the given
username and password. It will return the value that should be used for the
HTTP "Authorization" header. If it fails due to invalid username/password,
an error message will be returned.

This value can then be included in the HTTP "Authorization" header, like the
following: ::

    Authorization: <output of get-token>

For testing purposes, it is useful to use tools like the Chrome "app" called
"Advanced REST client", available at https://chrome.google.com/webstore/detail/advanced-rest-client/hgmloofddffdnphfgcellkdfbfbjeloo
or the Firefox addon "REST Easy", available at https://addons.mozilla.org/da/firefox/addon/rest-easy/

Requesting a SAML token manually
--------------------------------

.. Note::

   This section only applies covers using the *WSO2* IdP.

Although the Java MOX agent does this automatically, it can be useful
to request a SAML token manually, for testing purposes.

To request a SAML token, it is useful to use SoapUI.

Download SoapUI (http://www.soapui.org/) and import the project
provided in 'oio_rest/test_auth_data/soapui-saml2-sts-request.xml'.

Navigate to and double-click on: ::

    "sts" -> "wso2carbon-stsSoap11Binding" -> "Issue token - SAML 2.0"

Note: The value of <a:Address> element in <wsp:AppliesTo> must match your
SAML_MOX_ENTITY_ID setting. Change as needed.

The project assumes you are running the IdP server on https://localhost:9443/
(the default).

Execute the SOAP request. You can copy the response by clicking on the
"Raw" tab in the right side of the window and then selecting all, and
copying to the clipboard. Paste the response, making sure that the
original whitespace/indentation is preserved. Remove all elements/text
surrounding the <saml2:Assertion>..</saml2:Assertion> tag. Save to a
file, e.g. /my/saml/assertion.xml.

After requesting a SAML token, to make a REST request using the SAML token,
you need to pass in an HTTP Authorization header of a specific format: ::

    Authorization: saml-gzipped <base64-encoded gzip-compressed SAML assertion>

A script has been included to generate this HTTP header from a SAML token
XML file. This file must only contain the <saml2:Assertion> element.

To run it: ::

    python utils/encode_token.py /my/saml/assertion.xml

The output of this script can be used in a curl request by adding the
parameter -H, e.g.: ::

    curl -H "Authorization saml-gzipped eJy9V1................." ...

to the curl request. 

Alternately, if using bash shell: ::

    curl -H "$(python utils/encode_token.py" /my/saml/assertion.xml) ...


Licensing
=========

The MOX messaging queue, including the ActualState database, as found in this
project is free software. You are entitled to use, study, modify and share it
under the provisions of Version 2.0 of the Mozilla Public License as specified
in the LICENSE file. The license is available online at
https://www.mozilla.org/MPL/2.0/.

This software was developed by Magenta ApS, http://www.magenta.dk. For
feedback, feel  free to open an issue in the Github repository,
https://github.com/magenta-aps/mox. 

