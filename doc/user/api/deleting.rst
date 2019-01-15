.. _DeleteAttr:

===============================================================
Deleting attributes, states and relations when updating objects
===============================================================

This page describes deleting attributes, states and relation with an
:ref:`UpdateOperation`.

------------------------------
Example of deleting attributes
------------------------------

To clear / delete a previously set attribute value – lets say the egenskab
``supplement`` of a ``Facet``-object – specify the empty string as the attribute
value in the JSON body::

  …
  "attributter": {
          "facetegenskaber": [
              {
              "supplement": "",
              "virkning": {
                  "from": "2014-05-19",
                  "to": "infinity",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Clearing supplement, defined by a mistake."
              }
              }
          ]
      },
  …

To delete all previously set attribute values of a specific kind - for all
``virkning``-periods - you may simply specify an empty list for the given type
of attribute. Eg. to clear all ``egenskaber`` for a ``Facet`` - for all
``virkning``-periods, you should do this::

  …
  "attributter": {
          "facetegenskaber": [
             ]
      },
  …

Please notice, that this is different than omitting the list completely, in
which case, the specific attributes will not be updated at all. Eg. if you omit
the ``facetegenskaber``-key in the ``attributter``-object in the JSON body
supplied to the :ref:`UpdateOperation`, all the ``facetegenskaber`` of the
previous registration will be carried over untouched. ::

  ...
  "attributter": {
      },
  ...

--------------------------
Example of deleting states
--------------------------

Similar to the procedure stated above for the attributes - clearing/deleting
previously set states is done be supplying the empty string as value and the
desired virknings period. Eg. to clear state ``publiceret`` of a
``Facet``-object, the relevant part of the JSON body should look like this::

  ...
   "tilstande": {
          "facetpubliceret": [{
              "publiceret": "",
              "virkning": {
                  "from": "2014-05-19",
                  "to": "infinity",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Clearing publiceret, defined by a mistake."
              }
          }
          ]
      },
  ...


You can clear all states of a specific kind, by explicitly specifying a
completely empty list. Eg. to clear ``facetpubliceret`` for all
``virkning``-periods, the specific part of the JSON body should look like this:
::

  ...
   "tilstande": {
          "facetpubliceret": [
          ]
      },
  ...

Please notice, that this is different than omitting the list completly, in which
case, the specific state will not be updated at all. Eg. if you omit the
``facetpubliceret``-key in the ``tilstande``-object in the JSON body supplied to
the :ref:`UpdateOperation`, all the ``facetpubliceret`` state values of the
previous registration will be carried over untouched. ::

  ...
   "tilstande": {
      },
  ...

-----------------------------
Example of deleting relations
-----------------------------

Again, similar to the procedure stated above for the attributes and states,
clearing a previously set relation with cardinality 0..1 is done by supplying
empty strings for both ``uuid`` and ``urn`` of the relation. Eg. to clear a
previously set the ``ansvarlig`` of a ``Facet``-object, the specific part of the
JSON body would look like this::

  ...
  "relationer": {
          "ansvarlig": [
          {
              "uuid": "",
              "urn" : "",
              "virkning": {
                  "from": "2014-05-19",
                  "to": "infinity",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Nothing to see here!"

              }
          }
          ]
  }
  ...

When updating relations with unlimited cardinality (0..n), you have to supply
the full list - that is, all the relations of the particular type - and clearing
a particular relation of a given type is accordingly done by supplying the full
list sans the relation, that you wish to clear. (The exception to this is when
updating the ``Sag``-object, where you can specify an ``indeks`` of the relation
to only update a particular relation). To delete all the relations of a
particular type with unlimited cardinality (0..n) you must use the same
procedure as described above for relations with cardinality 0..1, where you
specify a single relation of the given type with an empty string for ``uuid``
and ``urn`` and with a ``virkning``-period as desired.


Specifying an explicitly empty object will clear all the relations of
the object. Eg.::

  ...
    "relationer": {}
  ...

Notice, that this is different than omitting the ``relationer``-key entirely,
which will carry over all the relations of the registration untouched.



-----------------------------
Dokument and Dokument Variant
-----------------------------

Dokument and Dokument Variant does have a few special considerations. This
section show some examples.


Deleting ``varianter`` of a ``Dokument``-object
-----------------------------------------------

To clear/delete a specific ``Dokument``-object Variant you need to need to clear
all the ``varianter`` ``egenskaber`` and Variant dele explicitly. Eg to clear
the ``offentliggørelsesvariant`` of a ``Dokument``-object you should supply the
specific part of the JSON body to the :ref:`UpdateOperation` like this: ::

  ...
  "varianter": [
      {
      "varianttekst": "offentliggørelsesvariant",
        "egenskaber": [],
        "dele": []
        },
  ...
  ]
  ...

To delete / clear all the ``varianter`` of a ``Dokument``-object, you should
explicitly specify an empty list in the JSON body. Eg. ::

  ...
  "varianter": [],
  ...

And again, please notice that this is different, than omitting the
``varianter``-key completely in the JSON body, which will carry over all the
``Dokument`` varianter of the previous registration untouched.

Deleting Dokument-Del of a Dokument Variant
-------------------------------------------

To clear / delete a specify Dokument Del of a Dokument Variant you
should clear all the Dokument Del 'egenskaber' and Dokument Del
relations explicitly. Eg. to clear the 'Kap. 1' Del of the
``offentliggørelsesvariant``, you should supply the specific part of the
JSON body to the update Dokument operation like this::

  ...
  "varianter": [
    {
      "varianttekst": "offentliggørelsesvariant",
      "dele": [
        "deltekst": "Kap. 1",
          "egenskaber": [],
          "relationer": []
        ]
    }
  ]
  ...

To clear / delete all the ``dele`` of a Variant, you should explicitly specify
an empty list. Eg. for Del ``Kap. 1`` of a ``offentliggørelsesvariant``, it
would look like this::

  ...
  "varianter": [
    {
      "varianttekst": "offentliggørelsesvariant",
      "dele": []
    }
  ]
  ...


Deleting ``egenskaber`` of a Dokument Del
-----------------------------------------

To clear all ``egenskaber`` of a Dokument Del for all ``virkning``-periods, you
should explicitly specify an empty list. Eg. to clear all the ``egenskaber`` of
a ``Kap. 1``-Del of a Dokument Variant it would look this: ::

  ...
  "varianter": [
    {
      "varianttekst": "offentliggørelsesvariant",
      "dele": [
        "deltekst": "Kap. 1",
          "egenskaber": []
        ]
    }
  ]
  ...

To clear some or all the ``egenskaber`` of a Dokument Del for a particular
``virkning`` period, you should use the empty string to clear the unwanted
values. Eg. to clear ``lokation``-egenskab value of ``Kap. 1`` of a
``offentliggørelsesvariant`` for the year 2014 the particular part of the JSON
body would look like this::

  ...
  "varianter": [
    {
      "varianttekst": "offentliggørelsesvariant",
      "dele": [
        "deltekst": "Kap. 1",
          "egenskaber": [
            {
             "lokation": ""
             "virkning": {
                  "from": "2014-01-01",
                  "to": "2015-01-01",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Clearing lokation for 2014"
                }
            }
          ],
        ]
    }
  ]
  ...

Deleting relations of a Dokument Del
------------------------------------

To clear all the relations of a particular Dokument Del, you should explictly
specify an empty list. Eg. to clear all the relations of the ``Kap. 1`` Dokument
Del of the ``offentliggørelsesvariant`` Variant, the specific part of the JSON
body would look like this::

  ...
  "varianter": [
    {
      "varianttekst": "offentliggørelsesvariant",
      "dele": [
        "deltekst": "Kap. 1",
          "relationer": []
        ]
    }
  ]
  ...

The delete / clear a specific relation of a Dokument Del you have to
specify the full list of the relations of the Dokument Del sans the
relation, that you wish to remove. In general, when updating the
Dokument Del relations, you have to specify the full list of relations.
