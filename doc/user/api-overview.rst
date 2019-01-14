============
API overview
============


This page will give you a wide but incomplete overview of the REST API. Refer to
:ref:`APIreference` for a complete reference.

Basic concepts
==============

Overview of some datatypes
--------------------------

The database contains a large number of datatypes. To illustrate the basic
operations of the API we introduce a subset here. Specifically a subset of
"Organisation".

The complete specifications for all the fields to organisation can be found in
reference document: `Specifikation af serviceinterface for Organisation`_.

.. _Specifikation af serviceinterface for Organisation: https://www.digitaliser.dk/resource/1569113/artefact/Specifikationafserviceinterfacefororganisation-OIO-Godkendt%5bvs.1.1%5d.pdf?artefact=true&PID=1569586


``organisation``
++++++++++++++++

Located at the endpoint :http:get:`/organisation/organisation`. A
``organisation`` is a legal organisation. A good example of this a municipality.
The database does support multiple ``organisation``, but in the wild there is
usually only one per MOX instance.


.. code-block:: json
   :caption: A small ``organisation`` with all the required fields highlighted.
   :emphasize-lines: 2-4,6-8,12-17

   {
     "attributter": {
       "organisationegenskaber": [{
         "brugervendtnoegle": "magenta-aps",
         "organisationsnavn": "Magenta ApS",
         "virkning": {
           "from": "2017-01-01",
           "to": "2019-03-14",
         }
       }]
     },
     "tilstande": {
       "organisationgyldighed": [{
         "gyldighed": "Aktiv",
         "virkning": {
           "from": "2017-01-01",
           "to": "2019-03-14",
         }
       }
     ]}
   }


The fields used in the example ``organisation`` are the following:

``organisationegenskaber→brugervendtnoegle``
    A id for the user. It is not necessarily unique. It is intended for the user
    to recognise the object. Required.

``organisationegenskaber→organisationsnavn``
    The official name of the organisation.

``organisationegenskaber→virkning``
    The period when the above attributes is valid. See :ref:`Valid time`.
    Required.

``organisationgyldighed→gyldighed``
    Whether the organisation is active or not. Can takae the values ``Aktiv``
    and ``Inaktiv``. Required.

``organisationgyldighed→virkning``
    The period when the above ``gyldighed`` is valid. See :ref:`Valid time`.
    Required.


``organisationenhed``
+++++++++++++++++++++

Located at the endpoint :http:get:`/organisation/organisationenhed`. A
``organisationenhed`` is a organisational unit. This could be a department,
section, office, committee, project group, class, team and the like. Usually a
``organisation`` contains a single ``organisationenhed`` as a direct decendant
with similar attributes as the parent ``organisation``. This
``organisationenhed`` inturn contains all of the organisational heirarchy.


.. code-block:: json
   :caption: A small ``organisationenhed`` with all the required fields
             highlighted.
   :emphasize-lines: 2-4,6-8,12-17

   {
     "attributter": {
       "organisationenhedegenskaber": [{
         "brugervendtnoegle": "copenhagen",
         "enhedsnavn": "Copenhagen",
         "virkning": {
           "from": "2017-01-01",
           "to": "2019-03-14",
         }
       }]
     },
     "tilstande": {
       "organisationenhedgyldighed": [{
         "gyldighed": "Aktiv",
         "virkning": {
           "from": "2017-01-01",
           "to": "2019-03-14",
         }
       }]
     },
     "relationer": {
       "overordnet": [{
         "uuid": "6ff6cf06-fa47-4bc8-8a0e-7b21763bc30a",
         "virkning": {
           "from": "2017-01-01",
           "to": "2019-03-14",
         }
       }],
       "tilhoerer": [{
         "uuid": "6135c99b-f0fe-4c46-bb50-585b4559b48a",
         "virkning": {
           "from": "2017-01-01",
           "to": "2019-03-14",
         }
       }]
     }
   }

The fields used in the example ``organisationenhed`` are the following:

``organisationenhedegenskaber→*`` and ``organisationenhedgyldighed→*``
   Similar to ``organisation``.

``relationer→tilhoerer``
   This in the root ``organisation`` which the ``organisationenhed`` is part of.
   This is usally set on all ``organisationenhed`` to the single
   ``organisation`` in the mox instance.

``relationer→overordnet``
  The parent ``organisationenhed``.

  On root ``organisationenhed``, it points to the ``organisation``. (This is a
  deliberate violation of the standard which only allows it to point to
  ``organisationenhed``.)


.. _Valid time:

Valid time
----------

The database is a `Bitemporal Database
<https://en.wikipedia.org/wiki/Temporal_database>`_. All attributes and
relations have a valid time period associated as ``virkning``.


.. code-block:: json
   :caption: A sample ``virkning`` with required fields
             highlighted.
   :emphasize-lines: 2,5

   {
     "from": "2017-01-01",
     "from_included": true,
     "to": "2025-12-31",
     "to_included": false
   }


The fields used in the example are the following:

``from``
    The time when this facts starts to be true. Date and time input is
    accepted in almost any reasonable format, including ISO 8601. Required.

``from_included``
    Whether the ``from`` timestamp is closed or open. Default ``true``.

``to``
    The time when this facts stop to be true. Date and time input is accepted
    in almost any reasonable format, including ISO 8601. Required.

``to_included``
    Whether the ``to`` timestamp is closed or open. Default ``false``.


All transactions also have a transaction time as ``registreret``.


Common operations
=================


.. _ReadOperation:

Read
----

To get a single object. Call :http:method:`GET` on the object endpoint with the
UUID of the object appended, e.g.:

.. code-block:: http

    GET /organisation/organisationenhed/1ab754c7-7126-494e-8a4d-9ee3054709fa HTTP/1.1

It will only return information which is currently valid. That is the
information with a :ref:`Valid time` containing the current system time.

To get a information which was valid at another time you can add
``&virkningFra=<datetime>&virkningTil=<datetime>`` Where ``<datetime>`` is a
date/time value. Date and time input is accepted in almost any reasonable
format, including ISO 8601.

Alternatively ``&virkningstid=<datetime>`` can be used. The results returned
will be those valid at date/time value ``<datetime>,`` giving a 'snapshot' of
the object's state at a given point in time.

To filter on the transaction time,
``&registreretFra=<datetime>&registreretTil=<datetime>`` and
``&registreringstid=<datetime>`` is also available.

See :http:get:`/organisation/organisationenhed/(regex:uuid)` for the complete
reference for read operation on ``organisationenhed``.


.. _ListOperation:

List
----

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


.. _SearchOperation:

Search
------

You can also *search* for an object by specifying values of attributes or
relations as search parameters. You can, e.g., find all ``organisation`` by
searching for any value of ``brugervendtnoegle``:

.. code-block:: http

    GET /organisation/organisation?brugervendtnoegle=% HTTP/1.1

All search parameters which search on an attribute value of type TEXT use
case-insensitive matching, with the possibility to use wildcards. Other
value types use a simple equality operator.

The wildcard character ``%`` (percent sign) may be used in these search
parameter values. This character matches zero or more of any characters.

If it is desired to search for attribute values of type TEXT which contain ``%``
themselves, then the character must be escaped in the search parameters with a
backslash, like, for example: ``abc\\%def`` would match the value ``abc%def``.
Contrary, to typical SQL LIKE syntax, the character ``_`` (underscore) matches
only the underscore character (and not "any character").

``bvn`` can be used as shorthand for ``brugervendtnoegle``, which is an
attribute field that all objects have, but apart from that, the attribute names
should be spelled out. Search parameter names are case-insensitive.


Search parameters may be combined and may include the time restrictions as for
:ref:`ListOperation`, so it is possible to search for a value which must exist
at a given time or interval.

Note that while the result of a :ref:`ListOperation` or :ref:`ReadOperation`
operation is given as the JSON representation of the object(s) returned, the
result of a :ref:`SearchOperation` operation is always given as a list of UUIDs
which may later be retrieved with a list or read operation - e.g:

.. code-block:: http

    GET /organisation/organisationenhed?brugervendtnoegle=Direktion&tilhoerer=urn:KL&enhedstype=urn:Direktion HTTP/1.1

    {
    "results": [[
        "7c6e38f8-e5b5-4b87-af52-9693e074f5ee",
        "9765cdbf-9f42-4e9d-897b-909af549aba8",
        "3ca64809-acdb-443f-9316-aabb2ee6aff7",
        "3eaa730c-7800-495a-9c6b-4688cdf7a61f",
        "7d305acc-2a85-420b-9557-feead3dae339"
        ]]
    }

Paged search
++++++++++++

The search function supports paged searches by adding the parameters
``maximalantalresultater`` (max number of results) and ``foersteresultat``
(first result).

Since pagination only makes sense if the order of the results are predictable
the search will be sorted by ``brugervendtnoegle`` if pagination is used.

Advanced search
+++++++++++++++

It is possible to search for relations (links) as well by specifying
the value, which may be either an UUID or a URN. E.g., for finding all
instances of ``organisationenhed`` which belongs to ``Direktion``:

.. code-block:: http

    GET /organisation/organisationenhed?tilknyttedeenheder=urn:Direktion HTTP/1.1


When searching on relations, one can limit the relation to a specific object
type by specifying a search parameter of the format::

    &<relation>:<objecttype>=<uuid|urn>

Note that the objecttype parameter is case-sensitive.

It is only possible to search on one ``DokumentVariant`` and ``DokumentDel`` at
a time. For example, if ::

    &deltekst=a&underredigeringaf=<UUID>

is specified, then the search will return documents which have a ``DokumentDel``
with ``deltekst="a"`` and which has the relation ``underredigeringaf=<UUID>``.
However, if the deltekst parameter is omitted, e.g. ::

    &underredigeringaf=<UUID>

Then, all documents which have at least one ``DokumentDel`` which has the given
UUID will be returned.

The same logic applies to the ``varianttekst`` parameter. If it is not
specified, then all variants are searched across. Note that when
``varianttekst`` is specified, then any ``DokumentDel`` parameters apply only to
that specific variant. If the ``DokumentDel`` parameters are matched under a
different variant, then they are not included in the results.


Searching on ``Sag``-``JournalPost``-relations
++++++++++++++++++++++++++++++++++++++++++++++

.. warning::

   This section should be moved to a API reference in the future.

To search on the sub-fields of the ``JournalPost`` relation in ``Sag``, requires
a special dot-notation syntax, due to possible ambiguity with other search
parameters (for example, the ``titel`` parameter).

The following are some examples::

  &journalpostkode=vedlagtdokument
  &journalnotat.titel=Kommentarer
  &journalnotat.notat=Læg+mærke+til
  &journalnotat.format=internt
  &journaldokument.dokumenttitel=Rapport+XYZ
  &journaldokument.offentlighedundtaget.alternativtitel=Fortroligt
  &journaldokument.offentlighedundtaget.hjemmel=nej

All of these parameters support wildcards (``%``) and use case-insensitive
matching, except ``journalpostkode``, which is treated as-is.

Note that when these parameters are combined, it is not required that the
matches occur on the *same* ``JournalPost`` relation.

For example, the following query would match any ``Sag`` which has one or more
``JournalPost`` relations which has a ``journalpostkode = "vedlagtdokument"``
AND which has one or more ``JournalPost`` relations which has a
``journaldokument.dokumenttitel = "Rapport XYZ"`` ::

  &journalpostkode=vedlagtdokument&journaldokument.dokumenttitel=Rapport+XYZ


.. _AddOperation:

Add
---


.. _UpdateOperation:

Update
------


.. _DeleteOperation:

Delete
------


.. _ImportOperation:

Import
------
