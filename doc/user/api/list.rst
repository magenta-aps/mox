.. _ListOperation:

--------------
List operation
--------------

It's also possible to use a slightly different syntax to list objects,
e.g.:

.. code-block:: http

    GET /organisation/organisationenhed/?uuid=1ab754c7-7126-494e-8a4d-9ee3054709fa HTTP/1.1

With this syntax is is possible to list more than one UUID:

.. code-block:: http

    GET /organisation/organisationenhed/?uuid=1ab754c7-7126-494e-8a4d-9ee3054709fa&uuid=a75af34e-1ce3-44d5-ae9a-76f246fd4b10&uuid=77cd9b29-ef12-418b-bde4-6703aea007e3 HTTP/1.1

That is, each UUID is specified by a separate ``&uuid=`` clause.

There is no built-in limit to how many objects can be listed in this way, but it
is often considered a best practice to limit URIs to a length of about 2000
characters. Thus, we recommend that you attempt to list a maximum of 45 objects
in each request.

List operations may include the time parameters ``virkningFra`` and
``virkningTil`` as well as ``registreringFra`` and ``registreringTil``. In this
case, only the parts of the objects which fall within these restrictions will be
given.

Given any parameters other than::

    registreretFra
    registreretTil
    registreringstid
    virkningFra
    virkningTil
    virkningstid
    uuid

the operation is a :ref:`SearchOperation` and will return a list a of UUIDs.


See :http:get:`/organisation/organisationenhed` for the complete reference for
list and search operation on ``organisationenhed``.

Known as a ``List`` operation in `the specification <Generelle egenskaber for
services på sags- og dokumentområdet>`_.
