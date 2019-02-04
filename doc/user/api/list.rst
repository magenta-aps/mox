.. _ListOperation:

--------------
List operation
--------------
.. http:get:: /(service)/(object)

   A List operation returns one or more whole objects as JSON.

   It is similar to a :ref:`ReadOperation`, but uses a slightly different
   syntax. The UUID is given as a parameter. With this syntax is is possible to
   list more than one UUID.

   .. note::

      :http:get:`/(service)/(object)` can also be a :ref:`SearchOperation`
      depending on parameters. With any the of ``uuid``, ``virking*`` and
      ``registeret`` parameters, it is a :ref:`ListOperation`. Given any other
      parameters the operation is a :ref:`SearchOperation` and will only return
      a list of UUIDs to the objects.

   Default is to return the object(s) as it is currently seen, but can optionally
   be constrained by ``virking*`` :ref:`valid time<Valid time>` and/or
   ``registrering*`` :ref:`transaction time<transaction time>` to give an older
   view.

   There is no built-in limit to how many objects can be listed in this way, but
   it is often considered a best practice to limit URIs to a length of about
   2000 characters. Thus, we recommend that you attempt to list a maximum of 45
   objects in each request.

   **List example request** for :http:get:`!GET /organisation/organisationenhed>`:

   .. code-block:: http

       GET /organisation/organisationenhed?uuid=74054d5b-54fc-4c9e-86ef-790fa6935afb&uuid=ccfd6874-09f5-4dec-8d39-781f614bb8a7 HTTP/1.1
       Accept: */*
       Host: example.com

   **List example response** for :http:get:`!GET /organisation/organisationenhed`:

   .. code-block:: http

       HTTP/1.0 200 OK
       Content-Length: 2150
       Content-Type: application/json
       Date: Thu, 17 Jan 2019 14:49:31 GMT
       Server: Werkzeug/0.14.1 Python/3.5.2

       {"results": [[{
                    "id": "74054d5b-54fc-4c9e-86ef-790fa6935afb",
                    "registreringer": [{
                            "attributter": {
                                "organisationenhedegenskaber": [{
                                        "brugervendtnoegle": "copenhagen",
                                        "enhedsnavn": "Copenhagen",
                                        "virkning": {
                                            "from": "2017-01-01 00:00:00+00",
                                            "from_included": true,
                                            "to": "2019-03-14 00:00:00+00",
                                            "to_included": false
                                        }}]},
                            "brugerref": "42c432e8-9c4a-11e6-9f62-873cf34a735f",
                            "fratidspunkt": {
                                "graenseindikator": true,
                                "tidsstempeldatotid": "2019-01-11T10:10:59.430647+00:00"
                            },
                            "livscykluskode": "Opstaaet",
                            "relationer": {
                                "overordnet": [{
                                        "uuid": "66e8a55a-8c61-4d33-b244-574c09ef41f7",
                                        "virkning": {
                                            "from": "2017-01-01 00:00:00+00",
                                            "from_included": true,
                                            "to": "2019-03-14 00:00:00+00",
                                            "to_included": false
                                        }}],
                                "tilhoerer": [{
                                        "uuid": "66e8a55a-8c61-4d33-b244-574c09ef41f7",
                                        "virkning": {
                                            "from": "2017-01-01 00:00:00+00",
                                            "from_included": true,
                                            "to": "2019-03-14 00:00:00+00",
                                            "to_included": false
                                        }}]},
                            "tilstande": {
                                "organisationenhedgyldighed": [{
                                        "gyldighed": "Aktiv",
                                        "virkning": {
                                            "from": "2017-01-01 00:00:00+00",
                                            "from_included": true,
                                            "to": "2019-03-14 00:00:00+00",
                                            "to_included": false
                                        }}]},
                            "tiltidspunkt": {
                                "tidsstempeldatotid": "infinity"
                            }}]},
                {
                    "id": "ccfd6874-09f5-4dec-8d39-781f614bb8a7",
                    "registreringer": [{
                            "attributter": {
                                "organisationenhedegenskaber": [{
                                        "brugervendtnoegle": "aarhus",
                                        "enhedsnavn": "Aarhus",
                                        "virkning": {
                                            "from": "2018-01-01 00:00:00+00",
                                            "from_included": true,
                                            "to": "2019-09-01 00:00:00+00",
                                            "to_included": false
                                        }}]},
                            "brugerref": "42c432e8-9c4a-11e6-9f62-873cf34a735f",
                            "fratidspunkt": {
                                "graenseindikator": true,
                                "tidsstempeldatotid": "2019-01-11T10:10:59.688454+00:00"
                            },
                            "livscykluskode": "Rettet",
                            "relationer": {
                                "overordnet": [{
                                        "uuid": "66e8a55a-8c61-4d33-b244-574c09ef41f7",
                                        "virkning": {
                                            "from": "2018-01-01 00:00:00+00",
                                            "from_included": true,
                                            "to": "2019-09-01 00:00:00+00",
                                            "to_included": false
                                        }}],
                                "tilhoerer": [{
                                        "uuid": "66e8a55a-8c61-4d33-b244-574c09ef41f7",
                                        "virkning": {
                                            "from": "2018-01-01 00:00:00+00",
                                            "from_included": true,
                                            "to": "2019-09-01 00:00:00+00",
                                            "to_included": false
                                        }}]},
                            "tilstande": {
                                "organisationenhedgyldighed": [{
                                        "gyldighed": "Aktiv",
                                        "virkning": {
                                            "from": "2018-01-01 00:00:00+00",
                                            "from_included": true,
                                            "to": "2019-09-01 00:00:00+00",
                                            "to_included": false
                                        }}]},
                            "tiltidspunkt": {
                                "tidsstempeldatotid": "infinity"
                            }}]}]]}

   :query uuid uuid: The UUID of the object to receive. Allowed multiple times in :ref:`ListOperation`.

   :query uuid brugerref: Match the ``brugerref``-field. The (system) user who changed the object.

   :query datetime registreretFra: :ref:`Transaction time` 'from' timestamp.
   :query datetime registreretTil: Transaction time 'to' timestamp.
   :query datetime registreringstid: Transaction time 'snapshot' timestamp.
   :query datetime virkningFra: :ref:`Valid time` 'from' timestamp.
   :query datetime virkningTil: Valid time 'to' timestamp.
   :query datetime virkningstid: Valid time 'snapshot' timestamp.

   All the ``registeret*`` and ``virkning*`` take a datetime. Input is accepted in
   almost any reasonable format, including ISO 8601, SQL-compatible, traditional
   POSTGRES, and others. The accepted values are the `Date/Time Input from
   PostgreSQL
   <https://www.postgresql.org/docs/9.5/datatype-datetime.html#DATATYPE-DATETIME-INPUT>`_.

   All *string* parameters match case insensitive. They support the wildcard
   operators ``_`` (underscore) to match a single character and ``%`` (percent
   sign) to match zero or more characters. The match is made with `ILIKE from
   PostgresSQL
   <https://www.postgresql.org/docs/9.5/functions-matching.html#FUNCTIONS-LIKE>`_.

   :resheader Content-Type: ``application/json``

   :statuscode 200: No error.
   :statuscode 400: Malformed JSON or other bad request.
   :statuscode 404: No object of a given class with that UUID.
   :statuscode 410: The object has been :ref:`deleted <DeleteOperation>`.

   Known as a ``List`` operation in `the specification
   <https://www.digitaliser.dk/resource/1567464/artefact/Generelleegenskaberforservicesp%c3%a5sags-ogdokumentomr%c3%a5det-OIO-Godkendt%5bvs.1.1%5d.pdf?artefact=true&PID=1763377>`_.
