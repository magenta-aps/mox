.. _ReadOperation:

--------------
Read operation
--------------
.. http:get:: /(service)/(object)/(uuid)

   The Read operation obtains an entire object as JSON.

   Default is to return the object as it is currently seen but can optionally
   be constrained by ``virking*`` :ref:`valid time<Valid time>` and/or
   ``registrering*`` :ref:`transaction time<transaction time>` to give an older
   view.

   **Example request** for :http:get:`!GET /organisation/organisation/(uuid)`:

   .. code-block:: http

       GET /organisation/organisation/5729e3f9-2993-4492-a56f-0ef7efc83111 HTTP/1.1
       Accept: */*
       Host: example.com

   **Example response** for :http:get:`!GET /organisation/organisation/(uuid)`:

   .. code-block:: http

       HTTP/1.0 200 OK
       Content-Length: 744
       Content-Type: application/json
       Date: Tue, 15 Jan 2019 12:27:16 GMT
       Server: Werkzeug/0.14.1 Python/3.5.2

       {"5729e3f9-2993-4492-a56f-0ef7efc83111": [{
                "id": "5729e3f9-2993-4492-a56f-0ef7efc83111",
                "registreringer": [{
                        "attributter": {
                            "organisationegenskaber": [{
                                    "brugervendtnoegle": "magenta-aps",
                                    "organisationsnavn": "Magenta ApS",
                                    "virkning": {
                                        "from": "2017-01-01 00:00:00+00",
                                        "from_included": true,
                                        "to": "2019-03-14 00:00:00+00",
                                        "to_included": false
                                    }}]},
                        "brugerref": "42c432e8-9c4a-11e6-9f62-873cf34a735f",
                        "fratidspunkt": {
                            "graenseindikator": true,
                            "tidsstempeldatotid": "2019-01-15T10:43:58.122764+00:00"
                        },
                        "livscykluskode": "Importeret",
                        "tilstande": {
                            "organisationgyldighed": [{
                                    "gyldighed": "Aktiv",
                                    "virkning": {
                                        "from": "2017-01-01 00:00:00+00",
                                        "from_included": true,
                                        "to": "2019-03-14 00:00:00+00",
                                        "to_included": false
                                    }}]},
                        "tiltidspunkt": {
                            "tidsstempeldatotid": "infinity"
                        }}]}]}



   :query datetime registreretFra: :ref:`Transaction time` 'from' timestamp.
   :query datetime registreretTil: Transaction time 'to' timestamp.
   :query datetime registreringstid: Transaction time 'snapshot' timestamp.
   :query datetime virkningFra: :ref:`Valid time` 'from' timestamp.
   :query datetime virkningTil: Valid time 'to' timestamp.
   :query datetime virkningstid: Valid time 'snapshot' timestamp.
   :query bool konsolider: Return consolidated 'virkning' periods - periods that are represented by the smallest amount of 'virkning' objects.

   All the ``registeret*`` and ``virkning*`` accept a value representing a
   specific date and time. Input is accepted in almost any reasonable format,
   including ISO 8601, SQL-compatible, traditional POSTGRES, and others. The
   accepted values are the `Date/Time Input from PostgreSQL
   <https://www.postgresql.org/docs/9.5/datatype-datetime.html#DATATYPE-DATETIME-INPUT>`_.

   :resheader Content-Type: ``application/json``

   :statuscode 200: No error.
   :statuscode 400: Malformed JSON or other bad request.
   :statuscode 404: No object of a given class with that UUID.
   :statuscode 410: The object has been :ref:`deleted <DeleteOperation>`.

   The Read operation is known as the ``Læs`` operation in `the specification
   <https://www.digitaliser.dk/resource/1567464/artefact/Generelleegenskaberforservicesp%c3%a5sags-ogdokumentomr%c3%a5det-OIO-Godkendt%5bvs.1.1%5d.pdf?artefact=true&PID=1763377>`_.
