==================
OIO REST API Notes
==================

.. contents:: `Table of contents`
   :depth: 5


Format of JSON body in requests to REST API
-------------------------------------------

Examples of the format of the JSON bodies to supply when invoking the
particular REST operations can be seen in the folder
``interface_test/test_data``.

Please note that the only distinction between an Update and an Import
operation is that in the Import, an object with the corresponding UUID
doesn't exist in the database. If it does, the PUT operation is
interpreted as an Update to replace the entire contents of the object.


File upload
-----------

When performing an import/create/update operation on a Dokument, it is
possible (if desired) to simultaneously upload files.
These requests should be made using multipart/form-data encoding.
The encoding is the same that is used for HTML upload forms.

The JSON input for the request should be specified in a "form" field called
"json". Any uploaded files should be included in the multpart/form-data
request as separate "form" fields.

The "indhold" attribute of any DokumentDel may be a URI pointing to
one of these uploaded file "fields". In that case, the URI must be of the
format::

    field:myfield

where myfield is the "form" field name of the uploaded file included in
the request that should be referenced by the DokumentDel.

It is also possible to specify any URI (e.g. ``http://....``, etc.) as the value
of the "indhold" attribute. In that case, the URI will be stored, however no
file will be downloaded and stored to the server. It is then expected that the
consumer of the API knows how to access the URI.

File download
-------------

When performing a read/list operation on a Dokument, the DokumentDel
subobjects returned will include an "indhold" attribute. This attribute has
a value that is the "content URI" of that file on the OIO REST API server.
An example::

    "indhold": "store:2015/08/14/11/53/4096a8df-ace7-477e-bda1-d5fdd7428a95.bin"

To download the file referenced by this URI, you must construct a request
similar to the following::

  http://localhost:5000/dokument/dokument/2015/08/14/11/53/4096a8df-ace7-477e-bda1-d5fdd7428a95.bin

Date ranges for Virkning
------------------------

In the XSDs, it's always possible to specify whether the end points are
included or not. In the API, this is presently *not* possible. The
Virkning periods will always default to "lower bound included, upper
bound not included".





Deleting / Clearing Attributes 
-------------------------------

To clear / delete a previously set attribute value – lets say the
egenskab 'supplement' of a Facet object – specify the empty string as
the attribute value in the JSON body::

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

To delete all previously set attribute values of a specific kind - for
all 'virknings' periods - you may simply specify an empty list for the
given type of attribute. Eg. to clear all 'egenskaber' for a Facet - for
all 'virknings' periods, you should do this::

  …
  "attributter": { 
          "facetegenskaber": [ 
             ]
      }, 
  …

Please notice, that this is different than omitting the list completely,
in which case, the specific attributes will not be updated at all. Eg.
if you omit the "facetegenskaber" key in the "attributes" object in the
JSON body supplied to the update operation, all the facetegenskaber of
the previous registration will be carried over untouched. ::

  ...
  "attributter": { 
      },
  ...

Deleting / Clearing States 
-------------------------------

Similar to the procedure stated above for the attributes -
clearing/deleting previously set states is done be supplying the empty
string as value and the desired virknings period. Eg. to clear state
'publiceret' of a Facet object, the relevant part of the JSON body
should look like this::

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
completely empty list. Eg. to clear "facetpubliceret" for all virkning
periods, the specific part of the JSON body should look like this: :: 

  ...
   "tilstande": { 
          "facetpubliceret": [
          ] 
      },
  ...

Please notice, that this is different than omitting the list completly,
in which case, the specific state will not be updated at all. Eg. if you
omit the "facetpubliceret" key in the "tilstande" object in the JSON
body supplied to the update operation, all the facetpubliceret state
values of the previous registration will be carried over untouched. ::

  ...
   "tilstande": { 
      },
  ...


Deleting / Clearing Relations
---------------------------------

Again, similar to the procedure stated above for the attributes and
states, clearing a previously set relation with cardinality 0..1 is done
by supplying empty strings for both uuid and urn of the relation. Eg. to
clear a previously set the 'ansvarlig' of a Facet object, the specific part
of the JSON body would look like this::

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
the full list - that is, all the relations of the particular type - and
clearing a particular relation of a given type is accordingly done by supplying 
the full list sans the relation, that you wish to clear. ( The exception to this
is when updating the Sag object, where you can specify an index of the
relation to only update a particular relation). To delete all the relations of
a particular type with unlimited cardinality (0..n) you must use the same 
procedure as described above for relations with cardinality 0..1, 
where you specify a single relation of the given type with an empty string for 
uuid and urn and with a 'virknings' period as desired.


Specifying an explicitly empty object will clear all the relations of
the object. Eg.::

  ...
    "relationer": {}
  ...

Notice, that this is different than omitting the "relationer"-key
entirely, which will carry over all the relations of the registration
untouched.


Deleting / Clearing "Varianter" of a Dokument object
----------------------------------------------------

To clear/delete a specific Dokument Variant you need to need to clear
all the Variant 'egenskaber' and Variant dele explicitly. Eg to clear
the "offentliggørelsesvariant" of a Dokument you should supply the
specific part of the JSON body to the update Dokument operation like
this: :: 

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

To delete / clear all the "varianter" of a Dokument, you should
explicitly specify an empty list in the JSON body. Eg. ::

  ...
  "varianter": [],
  ...

And again, please notice that this is different, than omitting the
"varianter"-key completely in the JSON body, which will carry over all
the Dokument varianter of the previous registration untouched.

Deleting / Clearing Dokument-Del of a Dokument-Variant
------------------------------------------------------

To clear / delete a specify Dokument Del of a Dokument Variant you
should clear all the Dokument Del 'egenskaber' and Dokument Del
relations explicitly. Eg. to clear the 'Kap. 1' Del of the
"offentliggørelsesvariant", you should supply the specific part of the
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

To clear / delete all the "Dele" of a Variant, you should explicitly
specify an empty list. Eg. for Del 'Kap. 1'  of a
"offentliggørelsesvariant, it would look like this::

  ...
  "varianter": [
    {
      "varianttekst": "offentliggørelsesvariant",
      "dele": []
    }
  ]
  ...


Deleting / Clearing 'egenskaber' of a Dokument Del
---------------------------------------------------

To clear all 'egenskaber' of a Dokument Del for all 'virknings' periods,
you should explicitly specify an empty list. Eg. to clear all the
'egenskaber' of a 'Kap. 1'-Del of a Dokument Variant it would look this:
::

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

To clear some or all the 'egenskaber' of a Dokument Del for a particular
'virknings' period, you should use the empty string to clear the
unwanted values. Eg. to clear 'lokation' egenskab value of 'Kap. 1' of a
'offentliggørelsesvariant' for the year 2014 the particular part of the
JSON body would look like this::

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

Deleting / Clearing relations of a Dokument Del
------------------------------------------------

To clear all the relations of a particular Dokument Del, you should
explictly specify an empty list. Eg. to clear all the relations of the
'Kap. 1' Dokument Del of the 'offentliggørelsesvariant' Variant, the
specific part of the JSON body would look like this::

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
