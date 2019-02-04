.. _CreateOperation:

----------------
Create operation
----------------

.. http:post:: /(service)/(object)

   The Create operation creates a new object from the JSON payload.
   :http:method:`POST` the JSON representation of its attributes, states and
   relations to the URL of the class. The Create operation returns a newly
   generated UUID for the created object.

   The data can be supplied directly in the request if
   :http:header:`Content-Type`: ``application/json`` is set.

   Alternatively the the data can be supplied as form-data in the ``json``-field
   with :http:header:`Content-Type`: ``multipart/form-data``. This allows
   seperate file form-data.


   **Example request** for :http:post:`!POST /organisation/organisationenhed`:

   .. code-block:: http

       POST /organisation/organisationenhed HTTP/1.1
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

   **Example response** for :http:post:`!POST /organisation/organisationenhed>`:

   .. code-block:: http

       HTTP/1.0 201 CREATED
       Content-Length: 48
       Content-Type: application/json
       Date: Mon, 21 Jan 2019 09:12:00 GMT
       Server: Werkzeug/0.14.1 Python/3.5.2

       {
           "uuid": "14b2abd4-ae3c-4a0f-b530-7a93443d729d"
       }

   :reqheader Content-Type: ``application/json`` or ``multipart/form-data``

   :statuscode 201: Object was created.
   :statuscode 400: Malformed JSON or other bad request.

   Known as a ``Opret`` operation in `the specification
   <https://www.digitaliser.dk/resource/1567464/artefact/Generelleegenskaberforservicesp%c3%a5sags-ogdokumentomr%c3%a5det-OIO-Godkendt%5bvs.1.1%5d.pdf?artefact=true&PID=1763377>`_.
