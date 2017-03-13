OIO REST API Notes
==================

.. contents:: `Table of contents`
   :depth: 5


You can find the current MOX specification here:

http://www.kl.dk/ImageVaultFiles/id_55874/cf_202/MOX_specifikation_version_0.PDF

As an example, you can find the Organisation hierarchy
here:

http://digitaliser.dk/resource/991439/artefact/Informations-+og+meddelelsesmodeller+for+Organisation+%5bvs.+1.1%5d.pdf

This version of the system implements four OIO hierarchies, namely
Klassifikation, Sag, Dokument and Organisation. In each installation of
the service, it is possible to only enable some of the hierarchies.


On this documentation
---------------------

This README file is a reStructuredText document, and an HTML version can
be obtained by running the command ::

    rst2html README.rst README.html

in a command prompt. Note that this requires Python Docutils to be
installed - on Ubuntu or Debian, this can be done with the following
command: ::

    sudo apt-get install python-docutils

If you're reading this on Github, you're probably seeing the HTML
rendering.

Audience
--------

This is a technical guide. You are not expected to have a profound knowledge of
the system as such, but you do have to know your way in a Bash prompt - you 
should be able to change the Apache configuration and e.g. disable or change
the SSL certificate on your own.

Getting started
===============

Configuration
-------------

The file ``db/config.sh`` contains configuration for the database, such
as which username/password to use to connect to the database, and which
database name to use.

To setup the database to send notifications to an AMQP message exchange,
the database must know how to connect to the AMQP server. The defaults
assume you have a local AMQP server and use the guest user. However,
these can be changed in ``db/config.sh`` prior to performing
installation.

The file ``oio_rest/oio_rest/settings.py`` contains configuration for
the generation of the database structure and the REST API. Set the
DATABASE, DB_USER and DB_PASSWORD settings according to what you have
chosen in ``db/config.sh``.

The FILE_UPLOAD_FOLDER setting allows you to change where the database
stores its files (used for storing the contents of binary files in the
Dokument hierarchy). The default is ``/var/mox``, and this is
automatically created by the install script.

There are some other settings that can be changed, and there should be
comments describing their purpose, or they are described in another
section of this document.

Installing
----------

To install the OIO REST API, run ``install.sh``

By default, you will be prompted to reinstall the python virtualenv
if it already exists, and reinstall/overwrite the database
if it already exists.

To always answer yes to these questions, pass the ``-y`` parameter.

Run ``install.sh -h`` for a list of options.

**NOTE:** PostgreSQL 9.3 or later is required. If PostgreSQL is not installed
on your system already, it will be during installation.

To run the API for testing or development purposes, run: ::

    oio_rest/oio_api.sh 

Then, go to http://localhost:5000/site-map to see a map of all available
URLs, assuming you're running this on your local machine.

The install.sh script creates an Apache VirtualHost for oio rest and 
MoxDocumentUpload.

To run the OIO Rest Mox Agent (the one listening for messages and
relaying them onwards to the REST interface), run: ::

    agents/MoxRestFrontend/moxrestfrontend.sh

**NOTE:** You can start the agent in the background by running: ::

    sudo service moxrestfrontend start

To test sending messages through the agent, run: ::

    ./test.sh

**NOTE:** The install script does not set up an IDP for SAML authentication,
which is enabled by default. If you need to test without SAML authentication, 
you will need to turn it off as described below. 

To request a token for the username from the IdP and output it in
base64-encoded gzipped format, run: ::

    ./auth.sh -u <username> -p

Insert your username in the command argument. You will be prompted to enter
a password.

If SAML authentication is turned on (i.e., if the parameter
``USE_SAML_AUTHENTICATION`` in ``oio_rest/oio_rest/settings.py`` is
``True``), the IDP must be configured correctly - see the corresponding
sections below for instruction on how to do this.


Quick install
-------------

These commands should get you up and running quickly on a machine with a 
completely new Ubuntu 14.04 Server Edition: ::

    sudo apt-get install git
    cd /srv
    sudo git clone https://github.com/magenta-aps/mox
    sudo chown -R <username>:<username> mox/
    cd mox
    ./install.sh

**Note:** The <username> must belong to the sudo user you're using for the
installation. We recommend creating a dedicated "mox" user and stripping its
sudo rights when everything works.

**Note:** This will install the system in ``/srv/mox``. It is of course
possible to install in any other location, but we do not recommend this 
for a quick install as it means a lot of configuration files need to be 
changed. In a later version, the user will be prompted for the location and 
the configuration will be generated accordingly.

**Note:** All commands, e.g. ``./test.sh``, are assumed to be issued from the
installation root directory, by default ``/srv/mox``.

Quick test
----------

Make sure the parameters ``USE_SAML_AUTHENTICATION`` in 
``oio_rest/oio_rest/settings.py`` is ``False``.

Make sure the parameter ``moxrestfrontend.rest.host`` in
``agents/MoxRestFrontend/moxrestfrontend.conf`` is set to
``http://localhost:5000``.

Start the (AMQP) MOX REST frontend agent: ::

    sudo service moxrestfrontend start

Start the REST API: ::

    oio_rest/oio_api.sh

Run the tests: ::

    ./test.sh

This should give you a lot of output like this: ::

    Deleting bruger, uuid: 1e874f85-07e5-40e5-81ed-42f21fc3fc9e
    Getting authtoken
    127.0.0.1 - - [27/Apr/2016 15:55:09] "DELETE /organisation/bruger/1e874f85-07e5-40e5-81ed-42f21fc3fc9e HTTP/1.1" 200 -
    Delete succeeded

**Note:** Currently, some of the tests will give the notice: "Result differs
from the expected". This is due to a bug in the tests, i.e. you should not
worry about this - if you see output as described above, the system is working.

For more advanced test or production setup, please study the rest of this 
README and follow your organization's best practices.


OIO REST API Notes
==================


Format of JSON body in requests to REST API
-------------------------------------------

Examples of the format of the JSON bodies to supply when invoking the
particular REST operations can be seen in the folder
``interface_test/test_data``.

Please note that the only distinction between an Update and an Import
operation is that in the Import, an object with the corresponding UUID
doesn't exist in the database. If it does, the PUT operation is
interpreted as an Update.

List/Search/Read operation common parameters
--------------------------------------------

All parameter names are case-insensitive.

Both the list, search, and read operations accept the following parameters: ::

    &virkningFra=<datotid>&virkningTil=<datotid>
    &registreretFra=<datotid>&registreretTil=<datotid>

Where <datotid> is a date/time value.  Date and time input is accepted
in almost any reasonable format, including ISO 8601.

If these parameters are omitted, they default to the time of the search,
giving the "actual state" as the results.

The results that are returned are filtered by those that overlap with the
given date/time ranges.

List operation
--------------

A GET request is interpreted as a list operation if, apart from date
ranges as specified above, only UUIDs are specified.

It's possible to *access* a single object at its URL, e.g.: ::

    https://referencedata.dk/klassifikation/klasse/1ab754c7-7126-494e-8a4d-9ee3054709fa


It's also possible to use a slightly different syntax to *list* objects,
e.g.: ::

    https://referencedata.dk/klassifikation/klasse?uuid=1ab754c7-7126-494e-8a4d-9ee3054709fa

The point of the last operation is that it is possible to list more than
one UUID. Accessing the following URL will, for instance, retrieve the
contents of three objects of the type Klasse: ::

   curl -H "Authorization: $AUTH_TOKEN" 'https://referencedata.dk/klassifikation/klasse?uuid=1ab754c7-7126-494e-8a4d-9ee3054709fa&uuid=a75af34e-1ce3-44d5-ae9a-76f246fd4b10&uuid=77cd9b29-ef12-418b-bde4-6703aea007e3' 

That is, each UUID is specified by a separate "&uuid=" clause.

There is no built-in limit to how many objects can be listed in this
way, but it is often considered a best practice to limit URIs to a
length of about 2000 characters. Thus, we recommend that you attempt to
list a maximum of 45 objects in each request.


Search operation
----------------

One is capable of searching for objects by all attributes, relations,
states (and variants and their corresponding DokumentDele, in the case
of Dokument). It is also possible to specify a single uuid to search on,
e.g. ::

    &uuid=4096a8df-ace7-477e-bda1-d5fdd7428a95

The results returned are only those which the user making the request is
allowed to see, according to the current restrictions present on the
object.

Search parameter names (attributes, relations, states, etc...) are
case-insensitive, e.g. to search on the "Ejer" attribute, one can specify
either: ::

    &ejer=urn:cpr12312323 or &Ejer=urn:cpr12312323

All search parameters which search on an attribute value of type TEXT use
case-insensitive matching, with the possibility to use wildcards. Other
value types use a simple equality operator. In the case of the Dokument
type, the "varianttekst" and "deltekst" parameters also support this type of
matching.

The wildcard character "%" (percent sign) may be used in these search
parameter values. This character matches zero or more of any characters.

If it is desired to search for attribute values of type TEXT which
contain "%" themselves, then the character must be escaped in the search
parameters with a backslash, like, for example: "abc\\%def" would match the
value "abc%def". Contrary, to typical SQL LIKE syntax, the character "_"
(underscore) matches only the underscore character (and not "any character").

When searching on relations, one can limit the relation to a specific object
type by specifying a search parameter of the format: ::

    &<relation>:<objecttype>=<uuid|urn>

Note that the objecttype parameter is case-sensitive.

It is only possible to search on one DokumentVariant and DokumentDel at a time.
For example, if ::

    &deltekst=a&underredigeringaf=<UUID>

is specified, then the search will return documents which have a DokumentDel
with deltekst="a" and which has the relation "underredigeringaf"=<UUID>.
However, if the deltekst parameter is omitted, e.g. ::

    &underredigeringaf=<UUID>

Then, all documents which have at least one DokumentDel which has the given
UUID will be returned.

The same logic applies to the "varianttekst" parameter. If it is not
specified, then all variants are searched across. Note that when
"varianttekst" is specified, then any DokumentDel parameters apply only
to that specific variant. If the DokumentDel parameters are matched
under a different variant, then they are not included in the results.

Searching on Sag JournalPost relations
++++++++++++++++++++++++++++++++++++++

To search on the sub-fields of the "JournalPost" relation in Sag, requires a
special dot-notation syntax, due to possible ambiguity with other search
parameters (for example, the "titel" parameter).

The following are some examples: ::

  &journalpostkode=vedlagtdokument
  &journalnotat.titel=Kommentarer
  &journalnotat.notat=Læg+mærke+til
  &journalnotat.format=internt
  &journaldokument.dokumenttitel=Rapport+XYZ
  &journaldokument.offentlighedundtaget.alternativtitel=Fortroligt
  &journaldokument.offentlighedundtaget.hjemmel=nej

All of these parameters support wildcards ("%") and use case-insensitive
matching, except "journalpostkode", which is treated as-is.

Note that when these parameters are combined, it is not required that the
matches occur on the *same* JournalPost relation.

For example, the following query would match any Sag which has one or more
JournalPost relations which has a journalpostkode = "vedlagtdokument" AND
which has one or more JournalPost relations which has a
journaldokument.dokumenttitel = "Rapport XYZ" ::

  &journalpostkode=vedlagtdokument&journaldokument.dokumenttitel=Rapport+XYZ

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
format: ::

    field:myfield

where myfield is the "form" field name of the uploaded file included in
the request that should be referenced by the DokumentDel.

It is also possible to specify any URI (e.g. "http://....", etc..) as the value
of the "indhold" attribute. In that case, the URI will be stored, however no
file will be downloaded and stored to the server. It is then expected that the
consumer of the API knows how to access the URI.

File download
-------------

When performing a read/list operation on a Dokument, the DokumentDel
subobjects returned will include an "indhold" attribute. This attribute has
a value that is the "content URI" of that file on the OIO REST API server.
An example: ::

    "indhold": "store:2015/08/14/11/53/4096a8df-ace7-477e-bda1-d5fdd7428a95.bin"

To download the file referenced by this URI, you must construct a request
similar to the following:
http://localhost:5000/dokument/dokument/2015/08/14/11/53/4096a8df-ace7-477e-bda1-d5fdd7428a95.bin

Date ranges for Virkning
------------------------

In the XSDs, it's always possible to specify whether the end points are
included or not. In the API, this is presently *not* possible. The
Virkning periods will always default to "lower bound included, upper
bound not included".


Merging Of Attributes / States / Relations When Updating Object
----------------------------------------------------------------

It is worth noting, that the current implementation of the REST-api and the 
underlying DB procedures as a general rule merges the incomming registration 
with the registration currently in effect for all 'virknings' periods not 
explictly covered by the incomming registration.


Exceptions to this rule
++++++++++++++++++++++++

- Deleting Attributes / States / Relations by explicitly specifying an empty 
  list / object 
  (see section below regarding clearing/deleting Attributes/States/Relations)

- When updating relations with *unlimited cardinality* (0..n) you always have to
  supply the full list of all the relations *of that particular type*. No 
  merging with the set of relations of the same particular type of the previous 
  registration takes place. However, if you omit the particular type of 
  relation entirely, when you're updating the object - all the relations of that 
  particular type of the previous registration, will be carried over.
- The relations in the services and object classes Sag, Aktivitet, Indsats and
  Tilstand have indices and behave differently - this will be described below.


Examples Of The Effects Of The Merging Logic When Updating Attributes
----------------------------------------------------------------------

As an example (purely made up to suit the purpose), lets say we have a Facet 
object in the DB, where the current 'Egenskaber' looks like this: ::

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
update operation: ::

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

The resulting 'Egenskaber' of the Facet would look like this: ::

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

As we can se, the update operation will merge the incoming fragment with 
the 'Egenskaber' of the current registration according to the 'virknings' periods
stipulated. The 'Egenskaber' fields not provided in the incomming fragment, will
be left untouched. If you wish to clear/delete particular 'Egenskaber' fields, see
the section 'Deleting / Clearing Attributes' regarding this.


Examples Of The Effects Of The Merging Logic When Updating States
----------------------------------------------------------------------

Lets say we have a Facet object, where the state 'Publiceret' look likes this 
in the DB: ::

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
the update operation of the REST-api: ::

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

The resulting 'Publiceret' state produced by the update operation, would look 
like this: ::

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

Hopefully it can be seen, that the update operation will merge the incoming 
fragment with the 'Publiceret' state of the current registration according to 
the 'virknings' periods stipulated. If you wish to clear/delete particular 
states, see the section 'Deleting / Clearing States' regarding this.


Examples Of The Effects Of The Merging Logic When Updating Relations
----------------------------------------------------------------------

As described in the section 'Merging Of Attributes / States / 
Relations When Updating Object' we differentiate between relations with 
cardinality 0..1 and 0..n (see beforementioned section).

Lets say we have an Facet object in the database, which has the following 
'ansvarlig' (cardinality 0..1) relation in place: ::

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


Lets say we now provide the following fragment as part of the incoming JSON 
body sent to the update operation: ::

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

The resulting 'ansvarlig' relation of the Facet object would look like this: ::

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

As it can be seen, the update operation has merged the incoming relation with
the 'ansvarlig' relation of the previous registration.

If you wish to delete / clear relations, see the section regading 
'Deleting / Clearing Relations'. 

If we want to update relations of a type with unlimited cardinality, we need to
supply *the full list* of the relations of that particalar type to the update
operation. Lets say we have a Facet object in the DB with the following 
'redaktoerer'-relations in place: ::

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
the update operation: ::

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

The resulting 'redaktoerer' part of the relations of the Facet object, 
will look like this: ::

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
relations with indices - specifically, the object classes Sag, Indsats, 
Aktivitet and Tilstand.

Also see the section named 'Deleting / Clearing Relations' for info regarding
clearing relations.


Behaviour of Relations of type Sag, Indsats, Tilstand and Aktivitet
-------------------------------------------------------------------

The relations with unlimited cardinality (0..n) of the Sag, Indsats, Tilstand
and Aktivitet objects are different
from the relations of the other object types, as they operate with an 'index' 
field. This means that you can update relations with unlimited cardinality 
without specifying the full list of the relations of the given type. You can 
update a specific relation instance, making use of its index value.

Lets say that you have a 'Sag' object with the following 'andrebehandlere' 
relations in place in the DB: ::

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
provided to the update operation of the Sag object: ::

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

The result would be the following: ::

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

As can be seen, the relation with index 2 has been updated and a new relation
with index 3 has been created. The relation with index 1 has been carried over
from the previous registration. Please notice, that in the case of relations
*of unlimited cardinality* for the Sag object, there is no merge logic regarding
'virknings' periods. 

To delete / clear a relation with a given index, you specify a blank uuid and/or
a blank urn for that particular index.

Please notice, that for the update, create and import operations of the 
Sag object, the rule is, that if you supply an index value that is unknown in 
the database, the specified index value will be ignored, and a new relation 
instance will be created with an index value computed by the logic in the 
DB-server. For the create and import operations, this will be all the specified 
index values.

Updating relations with cardinality 0..1 of the Sag object is done similarly to
updating relations of objects of other types. Any specified index values are
ignored and blanked by the logic of the update operation. Otherwise consult the
section 'Examples Of The Effects Of The Merging Logic When Updating Relations'
for examples and more info regarding this.


Deleting / Clearing Attributes 
-------------------------------

To clear / delete a previously set attribute value – lets say the
egenskab 'supplement' of a Facet object – specify the empty string as
the attribute value in the JSON body: ::

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
all 'virknings' periods, you should do this: ::

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
should look like this: ::

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
of the JSON body would look like this: ::

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
the object. Eg.: ::

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
explicitly specify an empty list in the JSON body. Eg. : ::

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
JSON body to the update Dokument operation like this: ::

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
"offentliggørelsesvariant, it would look like this: ::

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
JSON body would look like this: ::

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
specific part of the JSON body would look like this: ::

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


Sending Messages on the Beskedfordeler
======================================

Using the OIO Mox Library
-------------------------

.. Caution::

   **This section is currently out of date!!! Please refer to the
   examples above for more up to date details.**

This is located in the folder ``agent/`` in the Mox source code
repository.

The library is built with Apache Maven - see pom.xml for Maven dependencies. 

To send a command through the message queue, you first need a
``ObjectType`` representing the type of object you want to manipulate.

A collection of these can be defined in a properties file and loaded with ::

    Map<String, ObjectType> objectTypes = ObjectType.load(File propertiesFile) 

or ::

    Map<String, ObjectType> objectTypes = ObjectType.load(Properties properties). 
    
The properties must contain a set of keys adhering to the format: ::

    type.[name].[operation].method = [method]
    type.[name].[operation].path = [path]

For example: ::

    type.facet.create.method = POST
    type.facet.create.path = /klassifikation/facet

The default agent.properties file defines all of the classes from the
OIOXML hierarchies Klassifikation, Organisation, Sag and Dokument.

You can then get your ObjectType by calling get(String name) on the returned collection.


If you instead want to create your ObjectType yourself, you can create a
new ``ObjectType(String name)`` and add operations to it with ::

    addOperation(String name, ObjectType.Method method, String path)
    
where 

* ``name`` denotes the type of operation (usually "create", "update",
  "passivate" or "delete", but you can specify your own) 

* ``method`` denotes the HTTP method to use when connecting to the REST interface.
  Available are: GET, POST, PUT, DELETE and HEAD)

* ``path`` denotes the REST path, e.g. "/klassifikation/facet/[uuid]", and ``[uuid]`` will be
  replaced with a uuid you specify when calling the operation



You also need a ``MessageSender``  object, which can be created with: ::

    new MessageSender(String queueInterface, String queue);
    
where

* ``queueInterface`` is a hostname/port combination to the RabbitMQ
  instance, e.g. "localhost:5672", and

* ``queue``  is the RabbitMQ queue name, e.g. "incoming".
  
The queue name and interface port must match what the queue listener is
set up to use; the oio_moxagent listener is currently configured to use
the queue "incoming" for the RabbitMQ service on port 5672.



Now that you have an ObjectType instance and a MessageSender, you can
call any of the following methods:  

create 
++++++

::

    Future<String> create(MessageSender sender, JSONObject data)
    Future<String> create(MessageSender sender, JSONObject data, String authorization)

Sends a 'create' operation to the message queue, provided that a
'create' operation has been defined in the ObjectType. Put your JSON
document in the ``data`` field, and include an optional authorization
token for the REST interface. The demonstration class already contains
example code on how to obtain such a token (see the
``getSecurityToken()`` method in ``Main.java``) The function immediately
returns a ``Future<String>`` handle, which can be used to obtain the
server response. Calling the ``get()`` method on this handle blocks until a
response is ready, and then returns it in a String. 

update
++++++

::

    Future<String> update(MessageSender sender, UUID uuid, JSONObject data)
    Future<String> update(MessageSender sender, UUID uuid, JSONObject data, String authorization)

Sends an 'update' operation to the message queue, provided that an
'update' operation has been defined in the ObjectType. Add the document
UUID to be updated, as well as the JSON document you're updating with.  

passivate
+++++++++

::

    Future<String> passivate(MessageSender sender, UUID uuid, String note)
    Future<String> passivate(MessageSender sender, UUID uuid, String note, String authorization)

Sends a 'passivate' operation to the message queue, provided such an
operation has been defined in the ObjectType. Add the document UUID to
be passivated, as well as a note to go with the passivate operation (may
be null). 

delete 
++++++

::

    Future<String> delete(MessageSender sender, UUID uuid, String note)
    Future<String> delete(MessageSender sender, UUID uuid, String note, String authorization)

Sends a 'delete' operation to the message queue, provided such an
operation has been defined in the ObjectType. Add the document UUID to
be deleted, as well as a note to go with the delete operation (may be
null). 

sendCommand
+++++++++++

::

     Future<String> sendCommand(MessageSender sender, String operationName, UUID uuid, JSONObject data)
     Future<String> sendCommand(MessageSender sender, String operationName, UUID uuid, JSONObject data, String authorization)

Sends a custom operationName (useful if you added an operation other
than create, update, passivate or delete). Add a UUID and a JSON Object
as needed by the operation.

This is the more general function, which is used to implement the other
operations.


Using AMQP Messages
-------------------

If you do not wish to use the Java library described above, you can send
messages directly to the AMQP queue where the message handler is
running.

The message handler will recognize four AMQP headers when sending Mox
messages:

* "autorisation" - must contain the SAML token as described above.

* "objektID" - must contain the UUID of the object to manipulate; not
  used with create operations.

* "objekttype" - i.e., OIO class, e.g. "Facet".

* "operation", the action to be performed. Must be one of "create",
  "update", "passivate" or "delete".

Import operations can be performed with the "update" command - but note
that it's also possible to map new commands by editing the
``agent.properties`` file as described above. This could also be used to
specify read operations with GET, if so desired.

The content of the commands, i.e. the actual data, are send as the
payload of the messages. Note that while it is possible to specify a URL
when uploading a document, it is currently *not* possible to upload 
the binary contents of a document through the message queue - for this,
the REST interface must be used directly.

For an example of how to create and send Mox messages with Java, please
see the file ObjectType.java in
``agent/src/main/java/dk/magenta/mox/agent``.


Notification Messages
+++++++++++++++++++++

Each time a write operation (create/import/passivate/update/delete) is
performed, a notification messages is sent out by the database to an AMQP
message exchange called "mox.notifications".

This exchange is automatically created during the DB installation
using the "fanout" exchange type.
However, this can be modified later on the AMQP server.

The notification message has the following headers:

* "beskedtype" - always contains the value 'Notification'

* "objektID" - contains the UUID of the object.

* "objekttype" - i.e., OIO class, e.g. "Facet".

* "livscykluskode" - i.e. 'Opstaaet', 'Importeret', 'Passiveret', 'Slettet' or
  'Rettet'

The notification message has an empty body.
