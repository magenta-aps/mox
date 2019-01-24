.. _UpdateOperation:

----------------
Update operation
----------------

.. http:patch:: /(service)/(object)/(regex:uuid)

   An Update operation apply the JSON payload as a change to the object. Return
   the UUID of the object.

   How the changes are applied are described on the following pages. For the
   logic of merging see :ref:`API-merging`. To issue a patch that delete part of
   an object see :ref:`DeleteAttr`.


   The data can be supplied directly in the request if the header
   :http:header:`Content-Type`: ``application/json`` is set.

   Alternatively the the data can be supplied as form-data in the ``json``-field
   with the header :http:header:`Content-Type`: ``multipart/form-data``.

   :http:patch:`!PATCH /(service)/(object)/(regex:uuid)` can also be a
   :ref:`PassivateOperation` if ``livscyklus: "Passiv"`` is sent in the payload.

   Alternatively, use a :ref:`ImportOperation` to replace the entire object,
   including all ``virkning``-periods.

   **Example request** for :http:patch:`!PATCH /organisation/organisationenhed/(regex:uuid)`:

   .. code-block:: http

       PATCH /organisation/organisationenhed/5fc97a7c-70df-4e97-82eb-64dc0a0f5746 HTTP/1.1
       Content-Type: application/json
       Host: example.com

       {"relationer": {
            "adresser": [{
                    "urn": "dawa:0a3f50c4-379f-32b8-e044-0003ba298018",
                    "virkning": {
                        "from": "2018-01-01",
                        "to": "2019-09-01"
                    }}]}}

   **Example response** for :http:patch:`!PATCH /organisation/organisationenhed/(regex:uuid)`:

   .. code-block:: http

       HTTP/1.0 200 OK
       Content-Length: 48
       Content-Type: application/json
       Date: Mon, 21 Jan 2019 12:40:36 GMT
       Server: Werkzeug/0.14.1 Python/3.5.2

       {
           "uuid": "5fc97a7c-70df-4e97-82eb-64dc0a0f5746"
       }

   :reqheader Content-Type: ``application/json`` or ``multipart/form-data``

   :statuscode 200: Object was updated or passivated.
   :statuscode 400: Malformed JSON or other bad request.
   :statuscode 404: No object of a given class with that UUID.

   Known as a ``Ret`` operation in `the specification
   <https://www.digitaliser.dk/resource/1567464/artefact/Generelleegenskaberforservicesp%c3%a5sags-ogdokumentomr%c3%a5det-OIO-Godkendt%5bvs.1.1%5d.pdf?artefact=true&PID=1763377>`_.


.. toctree::
   :caption: Advanced Update
   :glob:

   update/merging.rst
   update/deleting.rst
