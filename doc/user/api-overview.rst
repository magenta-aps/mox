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

Located at the endpoint ``/organisation/organisation``. A ``organisation`` is a
legal organisation. A good example of this a municipality. The database does
support multiple ``organisation``, but in the wild there is usually only one per
MOX instance.


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

Located at the endpoint ``/organisation/organisationenhed``. A
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

The database is a `Temporal Database
<https://en.wikipedia.org/wiki/Temporal_database>`_. All attributes and
relations have a valid time period associated.


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
    The time when this facts starts to be true. This can be almost any timestamp format. Required.

``from_included``
    Whether the ``from`` timestamp is closed or open. Default ``true``.

``to``
    The time when this facts stop to be true. This can be almost any timestamp format.  Required.

``to_included``
    Whether the ``to`` timestamp is closed or open. Default ``false``.


Common operations
=================

Search
------

Read
----

Add
---

Update
------

Delete
------

Import
------
