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





