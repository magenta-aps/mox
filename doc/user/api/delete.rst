.. _DeleteOperation:

----------------
Delete operation
----------------

.. http:delete:: /(service)/(object)/(regex:uuid)

   The Delete operation deletes the object and return its UUID.

   After an object is deleted, it cannot be retrieved by :ref:`Read
   <ReadOperation>`, :ref:`List <ListOperation>` and :ref:`Search Operations
   <SearchOperation>` unless the ``registreretTil`` and/or ``registreretFra``
   indicate a period where it did exist.

   The Delete operation deletes the whole object. To delete part of an object
   see :ref:`DeleteAttr`.

   **Example request** for :http:delete:`!DELETE /organisation/organisationenhed/(regex:uuid)`:

   .. code-block:: http

       DELETE /organisation/organisationenhed/5fc97a7c-70df-4e97-82eb-64dc0a0f5746 HTTP/1.1
       Host: example.com


   **Example response** for :http:delete:`!DELETE /organisation/organisationenhed/(regex:uuid)`:

   .. code-block:: http

       HTTP/1.0 202 ACCEPTED
       Content-Length: 48
       Content-Type: application/json
       Date: Mon, 21 Jan 2019 16:47:00 GMT
       Server: Werkzeug/0.14.1 Python/3.5.2

       {
           "uuid": "5fc97a7c-70df-4e97-82eb-64dc0a0f5746"
       }


   :statuscode 202: Object was deleted.
   :statuscode 400: Malformed JSON or other bad request.
   :statuscode 404: No object of a given class with that UUID.


   Known as a ``Slet`` operation in `the specification
   <https://www.digitaliser.dk/resource/1567464/artefact/Generelleegenskaberforservicesp%c3%a5sags-ogdokumentomr%c3%a5det-OIO-Godkendt%5bvs.1.1%5d.pdf?artefact=true&PID=1763377>`_.
