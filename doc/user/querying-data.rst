.. _QueryingData:

Querying data
=============


.. contents:: `Table of contents`
   :depth: 5


Introduction
++++++++++++

In this document, the use of LoRa's REST interface for reading and
writing data is described.

The examples are given with the ``curl`` terminal command but should
work equally well with a browser plugin capable of sending HTTP ``POST``,
``PUT``, ``PATCH`` and ``DELETE`` requests.

.. note::
   As an example, the REST interface for Organisation is specified
   here: http://beta.rammearkitektur.dk/index.php/LoRA_Organisationsservice

Please note that in comparison with this official specification, our
system currently does not support the parameters ``-miljø`` and
``-version``.

As regards the parameter ``-miljø`` (which could be ``-prod``,
``-test``, ``-dev``, etc.) we have been trying to convince the
customer that we do not recommend running test, development and
production on the same systems, so we would prefer not to support that
parameter.

As regards the parameter ``-version``, we have deferred support for it
until we actually have more than one version of the protocol to support.


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


Appendix: Self-documentation
++++++++++++++++++++++++++++


* On a running LoRa system, it will always be possible to acquire, in
  JSON,  a sitemap of valid URLs on the ``/site-map/`` URL, e.g. located
  at https://mox/site-map.

* Similarly, for each service, a JSON representation of the
  hierarchy's classes and their fields may be found at the URL
  ``/<service>/classes/``, e.g. at
  https://mox/dokument/classes.


.. caution::

   The structure of each class is not completely analogous to the
   structure of the input JSON as it uses the concept of *"overrides"*.
   This should also be fixed.

