.. _ImportOperation:

----------------
Import operation
----------------

.. http:put:: /(service)/(object)/(uuid)

   The Import operation creates or overwrites an object from the JSON payload
   and returns the UUID for the object. The Import operation is similar to a
   :ref:`CreateOperation`, but you specify at which UUID.

   The Import operation creates a new object at the specified UUID if no object
   with the UUID exists or the object with that UUID have been :ref:`deleted
   <DeleteOperation>` or :ref:`passivated <PassivateOperation>`.

   If an object with the UUID does exist the Import operation `completely
   overwrites` the object including all ``virkning`` periods. This is useful if
   you want to change the ``virking`` periods.

   The JSON payload must contain a complete object in exactly the same format as
   for the :ref:`CreateOperation`.

   If there are no object with the UUID exist the Import operation sets
   ``livscykluskode: "Importeret"``.

   If an object is overwritten the Import operation sets ``livscykluskode:
   "Rettet"``.

   **Example request** for :http:put:`!PUT /organisation/organisationenhed/(uuid)`:

   .. code-block:: http

       PUT /organisation/organisationenhed/841190a7-0e70-468a-bd63-eb11ed615337 HTTP/1.1
       Content-Type: application/json
       Host: example.com

       {"attributter": {
            "organisationenhedegenskaber": [{
                    "brugervendtnoegle": "copenhagen",
                    "enhedsnavn": "Copenhagen",
                    "virkning": {
                        "from": "2017-01-01",
                        "to": "2019-03-14"
                    }}]},
        "relationer": {
            "overordnet": [{
                    "uuid": "6ff6cf06-fa47-4bc8-8a0e-7b21763bc30a",
                    "virkning": {
                        "from": "2017-01-01",
                        "to": "2019-03-14"
                    }}],
            "tilhoerer": [{
                    "uuid": "6135c99b-f0fe-4c46-bb50-585b4559b48a",
                    "virkning": {
                        "from": "2017-01-01",
                        "to": "2019-03-14"
                    }}]},
        "tilstande": {
            "organisationenhedgyldighed": [{
                    "gyldighed": "Aktiv",
                    "virkning": {
                        "from": "2017-01-01",
                        "to": "2019-03-14"
                    }}]}}


   **Example response** for :http:put:`!PUT /organisation/organisationenhed/(uuid)`:

   .. code-block:: http

       HTTP/1.0 200 OK
       Content-Length: 48
       Content-Type: application/json
       Date: Mon, 21 Jan 2019 10:17:19 GMT
       Server: Werkzeug/0.14.1 Python/3.5.2

       {
           "uuid": "841190a7-0e70-468a-bd63-eb11ed615337"
       }


   :reqheader Content-Type: ``application/json``

   :statuscode 200: Object was created or overwritten.
   :statuscode 400: Malformed JSON or other bad request.


   The Import operation is known as the ``Importer`` operation in `the
   specification
   <https://www.digitaliser.dk/resource/1567464/artefact/Generelleegenskaberforservicesp%c3%a5sags-ogdokumentomr%c3%a5det-OIO-Godkendt%5bvs.1.1%5d.pdf?artefact=true&PID=1763377>`_.
