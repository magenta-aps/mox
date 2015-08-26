Mox Messaging Service and Actual State Database
===============================================

This project contains an implementation (in PostgreSQL) of the OIO object
model, used as a standard for data exchange by the Danish government, for use
with a MOX messaging queue.

You can find the current MOX specification here:

http://www.kl.dk/ImageVaultFiles/id_55874/cf_202/MOX_specifikation_version_0.PDF

You can find the Organisation hierarchy, which is the first  part of the
specification to be supported by this database, here:

http://digitaliser.dk/resource/991439/artefact/Informations-+og+meddelelsesmodeller+for+Organisation+%5bvs.+1.1%5d.pdf


On this documentation
---------------------

This file is a reStructuredText document, and an HTML version can be
obtained by running the command ::

    rst2html README.rst README.html

in a command prompt. Note that this requires Python Docutils to be
installed - on Ubuntu or Debian, this can be done with the following
command: ::

    sudo apt-get install python-docutils

Getting started
===============

To install the OIO REST API, run ``install.sh``

**NOTICE:** If you need to initialize the postgresql database as well
you need to run run ``install.sh -d`` 

**CAUTION:** This will drop any existing mox database and any data in it will be lost.)


To run the API for testing or development purposes, run: ::

    oio_rest/oio_api.sh 

Then, go to http://localhost:5000/site-map to see a map of all available
URLs.

For deployment in production environments, please see the sample Apache
deployment in the config/ folder.


OIO REST API Notes
==================

Search operation
----------------

All search parameters which search on an attribute value use
case-insensitive matching, with the possibility to use wildcards. In
the case of the Dokument type, the "varianttekst" and "deltekst" parameters
also support this type of matching.

The wildcard character "%" (percent sign) may be used in parameters to the
search function. This character matches zero or more of any characters.

If it is desired to search for attribute values which
contain "%" themselves, then the character must be escaped in the search
parameters with a backslash, like, for example: "abc\%def" would match the
value "abc%def". Contrary, to typical SQL LIKE syntax, the character "_"
(underscore) matches only the underscore character (and not "any character").

File upload
-----------

When performing an import/create/update operation on a Dokument, it is
possible to simultaneously upload files.
These requests should be made using multipart/form-data encoding.
The encoding is the same used for HTML upload forms.

The JSON input for the request should be specified in a "form" field called
"json". Any uploaded files should be included in the multpart/form-data
request as separate "form" fields.
The "indhold" attribute of any DokumentDel must point be a URI pointing to
one of these uploaded file "fields". The URI must be of the format: ::

    field:myfield

where myfield is the "form" field name of the uploaded file included in
the request that should be referenced by the DokumentDel.

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


SAML Authentication
==========================================
To test SAML authentication, do the following:

You need a running STS (Security Token Service) running on your IdP.
An open-source STS is available from http://wso2.com/products/identity-server/
and is useful for testing. Download the binary, and follow the instructions
to run it.

To configure a STS, follow the instructions on
https://docs.wso2.com/display/IS500/Configuring+the+Identity+Server+to+Issue+Security+Tokens
(skip the part about Holder of Key).

Restart the WSO2 server! The STS endpoint simply did not work until I
restarted the WSO2 server.

OIO-REST SAML settings
----------------------

WSO2's default IdP entity ID is called "localhost". If you are using a
different IdP, you must change the SAML_IDP_ENTITY_ID setting to reflect your
IdP's entity ID.

For testing purposes, WSO2's IdP public certificate file is included in the
distribution.

If you are using a different IdP, you must change, specify the IdP's public
certificate file by setting in settings.py: ::

    SAML_IDP_CERTIFICATE = '/my/idp/certificate.pem'

In settings.py, turn on SAML authentication: ::

    USE_SAML_AUTHENTICATION = True


Requesting a SAML token
-----------------------

To request a SAML token, it is useful to use SoapUI.

Download SoapUI (http://www.soapui.org/) and import the project
provided in 'oio_rest/test_auth_data/soapui-saml2-sts-request.xml'.

Navigate to and double-click on: ::

    "sts" -> "wso2carbon-stsSoap11Binding" -> "Issue token - SAML 2.0"

Note: The value of <a:Address> element in <wsp:AppliesTo> must match your
SAML_MOX_ENTITY_ID setting. Change as needed.

The project assumes you are running the IdP server on https://localhost:9443/
(the default).

Execute the SOAP request. You can copy the response by clicking on the
"Raw" tab in the right side of the window and then selecting all, and
copying to the clipboard. Paste the response, making sure that the
original whitespace/indentation is preserved. Remove all elements/text
surrounding the <saml2:Assertion>..</saml2:Assertion> tag. Save to a
file, e.g. /my/saml/assertion.xml.

After requesting a SAML token, to make a REST request using the SAML token,
you need to pass in an HTTP Authorization header of a specific format: ::

    Authorization: saml-gzipped <base64-encoded gzip-compressed SAML assertion>

A script has been included to generate this HTTP header from a SAML token
XML file. This file must only contain the <saml2:Assertion> element.

To run it: ::

    python utils/encode_token.py /my/saml/assertion.xml

The output of this script can be used in a curl request by adding the
parameter -H, e.g.: ::

    curl -H "Authorization saml-gzipped eJy9V1................." ...

to the curl request. 

Alternately, if using bash shell: ::

    curl -H "$(python utils/encode_token.py" /my/saml/assertion.xml) ...


Format of JSON input files 
===========================

Examples of the format of the json files to supply when invoking the
particular REST operations can be seen in the folder
'/interface_test/test_data'.

Below here is listed some points to pay special attention to:

Deleting / Clearing Attributes 
------------------------------

To clear / delete a previously set attribute value – lets say the
egenskab 'supplement' of a facet object – specify the empty string as
the attribute value in the json body: ::

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


Deleting / Clearing States 
--------------------------

Similar to the procedure stated above - clearing/deleting previously set
states is done be supplying the empty string as value and the desired
virknings period. Eg. to clear state 'publiceret' of a facet object, the
relevant part of the JSON body should look like this: ::

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

Deleting / Clearing Relations
-----------------------------

Again, similar to the procedure stated above, clearing a previously set
relation with cardinality 0..1 is done by supplying empty strings for
both uuid and urn of the relation. Eg. to clear a previously set the
'ansvarlig' of a facet object, specific part of the JSON body would look
like this: ::

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
    ....

When updating relations unlimited cardinality (0..n), you have to supply
the full list (except for when updating the Sag object), and clearing a
particular relation is accordingly done by supplying the full list
without the relation that you wish to clear.


Licensing
=========

The MOX messaging queue, including the ActualState database, as found in this
project is free software. You are entitled to use, study, modify and share it
under the provisions of Version 2.0 of the Mozilla Public License as specified
in the LICENSE file. The license is available online at
https://www.mozilla.org/MPL/2.0/.

This software was developed by Magenta ApS, http://www.magenta.dk. For
feedback, feel  free to open an issue in the Github repository,
https://github.com/magenta-aps/mox. 

