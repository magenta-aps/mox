.. _PassivateOperation:

-------------------
Passivate operation
-------------------

.. http:patch:: /(service)/(object)/(regex:uuid)

   A Passivate operation is a special :ref:`UpdateOperation` with JSON-payload
   containing ``livscyklus: "Passiv"``. When an object is passive, it is no
   longer maintained and may not be updated. The object will afterwards not show
   up in searches and listings. The operation return the UUID of the object.

   The payload may contain an optional ``note``-field.

   :http:patch:`!PATCH /(service)/(object)/(regex:uuid)` can also be an
   :ref:`UpdateOperation` if ``livscyklus: "Passiv"`` is `not` sent in the
   payload.


   **Example request** for :http:patch:`!PATCH /organisation/organisationenhed/(regex:uuid)`:

   .. code-block:: http

      PATCH /organisation/organisationenhed/862bb783-696d-4345-9f63-cb72ad1736a3 HTTP/1.1
      Content-Type: application/json
      Host: example.com

      {
        "note": "Passivate this object!",
        "livscyklus": "Passiv"
      }

   **Example response** for :http:patch:`!PATCH /organisation/organisationenhed/(regex:uuid)`:

   .. code-block:: http

       HTTP/1.0 200 OK
       Content-Length: 48
       Content-Type: application/json
       Date: Mon, 21 Jan 2019 12:40:36 GMT
       Server: Werkzeug/0.14.1 Python/3.5.2

       {
           "uuid": "862bb783-696d-4345-9f63-cb72ad1736a3 HTTP/1.1"
       }

   :reqheader Content-Type: ``application/json``

   :statuscode 200: Object was updated or passivated.
   :statuscode 400: Malformed JSON or other bad request.
   :statuscode 404: No object of a given class with that UUID.

   Known as a ``Passiver`` operation in `the specification
   <https://www.digitaliser.dk/resource/1567464/artefact/Generelleegenskaberforservicesp%c3%a5sags-ogdokumentomr%c3%a5det-OIO-Godkendt%5bvs.1.1%5d.pdf?artefact=true&PID=1763377>`_.
