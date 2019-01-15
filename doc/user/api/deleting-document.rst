.. _DeletingDocument:

======================================
Deleting Dokument and Dokument Variant
======================================

Dokument and Dokument Variant have a few special considerations. This page show
some examples.


Deleting ``varianter`` of a ``Dokument``-object
===============================================

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
===========================================

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
=========================================

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
====================================

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
