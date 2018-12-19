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
