.. _API-merging:

=============
Merging logic
=============

When preforming a :ref:`UpdateOperation` some logic is applied to merge the new
data with the existing data. This page describes this logic.

It is worth noting, that the current implementation of the REST-api and the
underlying DB procedures as a general rule merges the incomming registration
with the registration currently in effect for all ``virkning``-periods not
explictly covered by the incomming registration.


Exceptions to this rule
=======================

- Deleting Attributes / States / Relations by explicitly specifying an empty
  list / object
  (see section below regarding clearing/deleting Attributes/States/Relations)
- When updating relations with *unlimited cardinality* (0..n) you always have to
  supply the full list of all the relations *of that particular type*. No
  merging with the set of relations of the same particular type of the previous
  registration takes place. However, if you omit the particular type of
  relation entirely, when you're updating the object - all the relations of that
  particular type of the previous registration, will be carried over.
- The relations in the services and object classes ``Sag``, ``Aktivitet``,
  ``Indsats`` and ``Tilstand`` have indices and behave differently - this will
  be described below.


Example of updating attributes
==============================

As an example (purely made up to suit the purpose), lets say we have a ``Facet``
object in the DB, where the current ``facetegenskaber`` looks like this::

  ...
  "facetegenskaber": [
              {
              "brugervendtnoegle": "ORGFUNK",
              "beskrivelse": "Organisatorisk funktion æ",
              "plan": "XYZ",
              "opbygning": "Hierarkisk",
              "ophavsret": "Magenta",
              "supplement": "Ja",
              "virkning": {
                  "from": "2014-05-19",
                  "to": "infinity",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Adjusted egenskaber"
              }
              }
  ]
  ...

Let's say we now supply the following fragment as part of the JSON body to the
:ref:`UpdateOperation`::

  ...
  "facetegenskaber": [
              {
              "supplement": "Nej",
              "virkning": {
                  "from": "2015-08-27",
                  "to": "2015-09-30",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Adjusted supplement"
                }
              }
  ]
  ...

The resulting ``facetegenskaber`` of the ``Facet`` would look like this::

  ...
  "facetegenskaber": [
              {
              "brugervendtnoegle": "ORGFUNK",
              "beskrivelse": "Organisatorisk funktion æ",
              "plan": "XYZ",
              "opbygning": "Hierarkisk",
              "ophavsret": "Magenta",
              "supplement": "Ja",
              "virkning": {
                  "from": "2014-05-19",
                  "to": "2015-08-27",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Adjusted egenskaber"
                }
              }
              ,
               {
              "brugervendtnoegle": "ORGFUNK",
              "beskrivelse": "Organisatorisk funktion æ",
              "plan": "XYZ",
              "opbygning": "Hierarkisk",
              "ophavsret": "Magenta",
              "supplement": "Nej",
              "virkning": {
                  "from": "2015-08-27",
                  "to": "2015-09-30",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Adjusted supplement"
                }
              }
              ,{
              "brugervendtnoegle": "ORGFUNK",
              "beskrivelse": "Organisatorisk funktion æ",
              "plan": "XYZ",
              "opbygning": "Hierarkisk",
              "ophavsret": "Magenta",
              "supplement": "Ja",
              "virkning": {
                  "from": "2015-09-30",
                  "to": "infinity",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Adjusted egenskaber"
                }
              }

  ]
  ...

As we can se, the update operation will merge the incoming fragment with the
``facetegenskaber`` of the current registration according to the
``virkning``-periods stipulated. The ``facetegenskaber``-fields not provided in
the incomming fragment, will be left untouched. If you wish to clear/delete
particular ``facetegenskaber``-fields, see :ref:`DeleteOperation`.


Example of updating states
==========================

Lets say we have a ``Facet``-object, where the state ``facetpubliceret`` look
likes this in the DB::

  ...
  "tilstande": {
          "facetpubliceret": [{
              "publiceret": "Publiceret",
              "virkning": {
                  "from": "2014-05-19",
                  "to": "infinity",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Publication Approved"
              }
          }
          ]
      },
  ...

Lets say that we now, provide the following fragment as part of the JSON body to
the :ref:`UpdateOperation` of the REST-api::

  ...
  "tilstande": {
          "facetpubliceret": [{
              "publiceret": "IkkePubliceret",
              "virkning": {
                  "from": "2015-01-01",
                  "to": "2015-12-31",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Temp. Redacted"
              }
          }
          ]
      },
  ...

The resulting ``facetpubliceret`` state produced by the :ref:`UpdateOperation`,
would look like this::

  ...
  "tilstande": {
          "facetpubliceret": [{
              "publiceret": "Publiceret",
              "virkning": {
                  "from": "2014-05-19",
                  "to": "2015-01-01",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Publication Approved"
              }
          },
          {
              "publiceret": "IkkePubliceret",
              "virkning": {
                  "from": "2015-01-01",
                  "to": "2015-12-31",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Temp. Redacted"
              }
          },
          {
              "publiceret": "Publiceret",
              "virkning": {
                  "from": "2015-12-31",
                  "to": "infinity",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Publication Approved"
              }
          }
          ]
      },
  ...

Hopefully it can be seen, that the :ref:`UpdateOperation` will merge the incoming
fragment with the ``facetpubliceret`` state of the current registration according to
the ``virkning``-periods stipulated. If you wish to clear/delete particular
states, see :ref:`DeleteOperation`.


.. _UpdatingRelations:

Example of updating relations
=============================

As described in the top section we differentiate between relations with
cardinality 0..1 and 0..n.

Lets say we have an ``Facet``-object in the database, which has the following
``ansvarlig`` (cardinality 0..1) relation in place::

  ...
  "relationer": {
          "ansvarlig": [
          {
              "uuid": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
              "virkning": {
                  "from": "2014-05-19",
                  "to": "infinity",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Initial Responsible Set"
              }
          }
        ]
      }
  ...


Lets say we now provide the following fragment as part of the incoming JSON body
sent to the :ref:`UpdateOperation`::

  ...
  "relationer": {
          "ansvarlig": [
          {
              "uuid": "ef2713ee-1a38-4c23-8fcb-3c4331262194",
              "virkning": {
                  "from": "2015-02-14",
                  "to": "2015-06-20",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Change of responsible"
              }
          }
          ]
        }
  ...

The resulting ``ansvarlig``-relation of the ``Facet``-object would look like
this::

  ...
  "relationer": {
          "ansvarlig": [
          {
              "uuid": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
              "virkning": {
                  "from": "2014-05-19",
                  "to": "2015-02-14",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Initial Responsible Set"
              }
          }
          ,{
              "uuid": "ef2713ee-1a38-4c23-8fcb-3c4331262194",
              "virkning": {
                  "from": "2015-02-14",
                  "to": "2015-06-20",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Change of responsible"
              }
          },
           {
              "uuid": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
              "virkning": {
                  "from": "2015-06-20",
                  "to": "infinity",
                  "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                  "aktoertypekode": "Bruger",
                  "notetekst": "Initial Responsible Set"
              }
          }
        ]
      }
  ...

As it can be seen, the :ref:`UpdateOperation` has merged the incoming relation
with the ``ansvarlig``-relation of the previous registration.

If you wish to delete / clear relations, see the section regading
:ref:`DeleteOperation`.

If we want to update relations of a type with unlimited cardinality, we need to
supply *the full list* of the relations of that particalar type to the
:ref:`UpdateOperation`. Lets say we have a ``Facet``-object in the DB with the
following ``redaktoerer``-relations in place::

  ...
  "relationer": {
     "redaktoerer": [
            {
                "uuid": "ef2713ee-1a38-4c23-8fcb-3c4331262194",
                "virkning": {
                    "from": "2014-05-19",
                    "to": "infinity",
                    "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                    "aktoertypekode": "Bruger",
                    "notetekst": "First editor set"
                }
            },
                {
                    "uuid": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                    "virkning": {
                        "from": "2015-08-20",
                        "to": "infinity",
                        "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                        "aktoertypekode": "Bruger",
                        "notetekst": "Second editor set"
                    }
                }
            ]
        }
  ...


Lets say we now provide the following fragment as part of the JSON body sent to
the :ref:`UpdateOperation`::

  ...
  "relationer": {
     "redaktoerer": [
                {
                    "uuid": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                    "virkning": {
                        "from": "2015-08-26",
                        "to": "infinity",
                        "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                        "aktoertypekode": "Bruger",
                        "notetekst": "Single editor now"
                    }
                }
            ]
        }
  ...

The resulting ``redaktoerer``-part of the relations of the ``Facet``-object,
will look like this::

  ...
  "relationer": {
     "redaktoerer": [
                {
                    "uuid": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                    "virkning": {
                        "from": "2015-08-26",
                        "to": "infinity",
                        "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                        "aktoertypekode": "Bruger",
                        "notetekst": "Single editor now"
                    }
                }
            ]
        }
  ...


As we can see no merging has taken place, as we in this example are updating
relations of a type with unlimited cardinality (0..n).

As explained above, this works differently for "new-style" relations, i.e.
relations with indices - specifically, the object classes ``Sag``, ``Indsats``,
``Aktivitet`` and ``Tilstand``.

Also see the section named :ref:`DeleteOperation` for info regarding clearing
relations.


Relations of type ``Sag``, ``Indsats``, ``Tilstand`` and ``Aktivitet``
----------------------------------------------------------------------

The relations with unlimited cardinality (0..n) of the ``Sag``, ``Indsats``,
``Tilstand`` and ``Aktivitet``-objects are different from the relations of the
other object types, as they operate with an 'index' field. This means that you
can update relations with unlimited cardinality without specifying the full list
of the relations of the given type. You can update a specific relation instance,
making use of its index value.

Lets say that you have a ``Sag``-object with the following
``andrebehandlere``-relations in place in the DB::

  ...
  "relationer": {
        "andrebehandlere": [{
            "objekttype": "Bruger",
            "indeks": 1,
            "uuid": "ff2713ee-1a38-4c23-8fcb-3c4331262194",
            "virkning": {
                "from": "2014-05-19",
                "to": "infinity",
                "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                "aktoertypekode": "Bruger",
                "notetekst": "As per meeting d.2014-05-19"
            }
        },
        {
            "objekttype": "Organisation",
            "indeks": 2,
            "uuid": "ddc99abd-c1b0-48c2-aef7-74fea841adae"
            ,"virkning": {
                "from": "2015-02-20",
                "to": "infinity",
                "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                "aktoertypekode": "Bruger",
                "notetekst": "As per meeting 2015-02-20"
            },
        }
        ]
  }
  ...

Lets say you now provide the following fragment as part of the JSON body
provided to the :ref:`UpdateOperation` of the ``Sag``-object::

  ...
  "relationer": {
  "andrebehandlere": [
              {
                "objekttype": "Organisation",
                "indeks": 2,
                "uuid": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                "virkning": {
                    "from": "2015-05-20",
                    "to": "2015-08-20",
                    "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                    "aktoertypekode": "Bruger",
                    "notetekst": "As per meeting d.2015-02-20"
                },
            },
            {
                "objekttype": "Organisation",
                "uuid": "ef2713ee-1a38-4c23-8fcb-3c4331262194"
                ,"virkning": {
                    "from": "2015-08-20",
                    "to": "infinity",
                    "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                    "aktoertypekode": "Bruger",
                    "notetekst": "As per meeting 2015-08-20"
                },
            },
        ]
  }
  ...

The result would be the following::

  ...
  "relationer": {
  "andrebehandlere": [
              {
                "objekttype": "Bruger",
                "indeks": 1,
                "uuid": "ff2713ee-1a38-4c23-8fcb-3c4331262194",
                "virkning": {
                    "from": "2014-05-19",
                    "to": "infinity",
                    "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                    "aktoertypekode": "Bruger",
                    "notetekst": "As per meeting d.2014-05-19"
                },
            },
              {
                "objekttype": "Organisation",
                "indeks": 2,
                "uuid": "ddc99abd-c1b0-48c2-aef7-74fea841adae"
                ,"virkning": {
                    "from": "2015-05-20",
                    "to": "2015-08-20",
                    "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                    "aktoertypekode": "Bruger",
                    "notetekst": "As per meeting d.2015-02-20"
                },
            },
            {
                "objekttype": "Organisation",
                "indeks": 3,
                "uuid": "ef2713ee-1a38-4c23-8fcb-3c4331262194"
                ,"virkning": {
                    "from": "2015-08-20",
                    "to": "infinity",
                    "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                    "aktoertypekode": "Bruger",
                    "notetekst": "As per meeting 2015-08-20"
                },
            },
        ]
  }
  ...

As can be seen, the relation with ``"indeks": 2`` has been updated and a new
relation with ``"indeks": 3`` has been created. The relation with ``"indeks":
1`` has been carried over from the previous registration. Please notice, that in
the case of relations *of unlimited cardinality* for the ``Sag``-object, there
is no merge logic regarding ``virkning``-periods.

To delete / clear a relation with a given ``indeks``, you specify a blank ``uuid``
and/or a blank ``urn`` for that particular ``indeks``.

Please notice, that for the :ref:`UpdateOperation`, :ref:`CreateOperation` and
:ref:`ImportOperation` of the ``Sag``-object, the rule is, that if you supply an
``indeks``-value that is unknown in the database, the specified ``indeks``-value
will be ignored, and a new relation instance will be created with an
``indeks``-value computed by the logic in the DB-server. For the
:ref:`CreateOperation` and :ref:`ImportOperation`, this will be all the
specified index values.

Updating relations with cardinality 0..1 of the ``Sag``-object is done similarly
to updating relations of objects of other types. Any specified ``indeks``-values
are ignored and blanked by the logic of the :ref:`UpdateOperation`. Otherwise
consult :ref:`UpdatingRelations` for examples and more info regarding this.
