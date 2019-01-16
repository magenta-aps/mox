.. _FileOperations:

=================
 File operations
=================


.. _FileUpoadOperation:

File upload
===========

When performing an :ref:`ImportOperation`, :ref:`CreateOperation` or
:ref:`Updateoperation` on a ``Dokument``, it is possible (if desired) to
simultaneously upload files. These requests should be made using
``multipart/form-data``-encoding. The encoding is the same that is used for HTML
upload forms.

The JSON input for the request should be specified in a ``form``-field called
``json``. Any uploaded files should be included in the multpart/form-data
request as separate ``form``-fields.

The ``indhold``-attribute of any ``DokumentDel`` may be a URI pointing to one of
these uploaded file "fields". In that case, the URI must be of the format::

    field:myfield

where myfield is the ``form```-field name of the uploaded file included in the
request that should be referenced by the ``DokumentDel``.

It is also possible to specify any URI (e.g. ``http://....``, etc.) as the value
of the ``indhold``-attribute. In that case, the URI will be stored, however no
file will be downloaded and stored to the server. It is then expected that the
consumer of the API knows how to access the URI.


.. _FileDownloadOperation:

File download
=============

When performing a :ref:`ReadOperation` or :ref:`ListOperation` on a
``Dokument``, the ``DokumentDel``-subobjects returned will include an
``indhold`` attribute. This attribute has a value that is the "content URI" of
that file on the OIO REST API server. An example::

    "indhold": "store:2015/08/14/11/53/4096a8df-ace7-477e-bda1-d5fdd7428a95.bin"

To download the file referenced by this URI, you must construct a request
similar to the following::

  http://localhost:5000/dokument/dokument/2015/08/14/11/53/4096a8df-ace7-477e-bda1-d5fdd7428a95.bin
