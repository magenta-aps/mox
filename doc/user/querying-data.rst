.. _QueryingData:

Querying data
=============


.. contents:: `Table of contents`
   :depth: 5


A note for developers
---------------------

This guide assumes that the LoRA installation uses SAML
authentication, which is the case when interacting with deployed
instances. For development, however, it is frequently easier to
disable authentication in ``settings.py``::

  USE_SAML_AUTHENTICATION = False

In this case, you may safely disregard all talk of *SAML* tokens, the
:http:header:`Authorization` header and ``AUTH_TOKEN``.

Acquiring a SAML token
++++++++++++++++++++++

A SAML STS token recognized by the system may be acquired by any means.
Please note that for login to proceed and the user's permissions to be
calculated correctly, the user must exist in the organisation, e.g. (as
in the case with referencedata.dk) by linking the IdP with an
Organisation service.

At present, however, a token is acquired by calling the function
`get-token` in the REST interface.

This can be done manually, through a browser, or through the command
line::

    curl -X POST -d "username=example&password=password" \
      https://mox/get-token


This token will, in the current application, be valid for five minutes.
Different time spans or authentication schemes should be considered.


