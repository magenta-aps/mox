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




Updating and creating data
++++++++++++++++++++++++++

To update existing and create new objects, the HTTP ``PUT``,
``POST`` and ``PATCH`` methods are used, respectively. Use the request
body to supply the data in _JSON_ form. Either directly with the :http:header:`Content-Type`
as ``application/json`` as form data with a :http:header:`Content-Type` of
``multipart/form-data`` and a single field, `json`, containing the data.

Examples of valid JSON data for creation, update and import can be found
in the directory ``oio_rest/tests/fixtures/`` in the source code.



Update
------

To change an object, issue a ``PATCH`` request containing the JSON
representation of the changes as they apply to the object's attributes,
states and relations.

The ``PATCH`` request must be issued to the object's URL - i.e., including the
UUID.

An example::

    curl -k -sH "Content-Type: application/json" \
      -X PATCH -d "<JSON DATA>" \
      -H "Authorization: $AUTH_TOKEN" \
      https://mox/klassifikation/klasse/39a6ef88-ae26-4557-a48c-7d7c5662c609

Alternatively, use a ``PUT`` to replace the entire object, including all
Virkning periods.

Import
------

As in the case with update, an import is done with a PUT request. This
basically means that the distinction between an import and an update is
that in the case of an *import*, no object with the given UUID exists in
the system. One might say that an import is an update of an object which
does not (yet) exist in this system.

The data must contain a complete object in exactly the same format as
for the create operation, but must be PUT to the objects URL as given by
its UUID.

An example::

    curl -k -sH "Content-Type: application/json" \
      -H "Authorization: $AUTH_TOKEN" \
      -X PUT -d "JSON DATA" \
      /klassifikation/facet/1b1e2de1-6d95-4200-9b60-f85e70cc37cf


Passivating and deleting data
+++++++++++++++++++++++++++++

Passivate
---------

An object is passivated by sending a special update (using a PATCH
request) whose JSON data only contains two fields, an optional note
field and the life cycle code "Passiv".

E.g., the JSON may look like this::

    {
        "Note": "Passivate this object!",
        "livscyklus": "Passiv"
    }


When an object is passive, it is no longer maintained and may not be
updated.


Delete
------

An object is deleted by sending a ``DELETE`` request. This might e.g.
look like this::

    curl -k -sH "Content-Type: application/json" \
      -H "Authorization: $AUTH_TOKEN" \
      -X DELETE \
      -d "$(cat test_data/facet_slet.json)" \
      https://mox/organisation/organisationenhed/7c6e38f8-e5b5-4b87-af52-9693e074f5ee

After an object is deleted, it may still be retrieved by a read or list
operation, but it will not appear in search results unless the
registreretTil and/or registreretFra indicate a period where it did
exist.

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

