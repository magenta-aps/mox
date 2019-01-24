.. _PassivateOperation:

-------------------
Passivate operation
-------------------

An object is passivated by sending a special :ref:`UpdateOperation` (using a
:http:method:`PATCH`-request) whose JSON data only contains two fields, an
optional note field and the life cycle code ``Passiv``.

E.g., the JSON may look like this:

.. code-block:: http

    PATCH /organisation/organisationenhed/862bb783-696d-4345-9f63-cb72ad1736a3 HTTP/1.1
    Content-Type: application/json

    {
        "Note": "Passivate this object!",
        "livscyklus": "Passiv"
    }


When an object is passive, it is no longer maintained and may not be
updated.

Known as a ``Passiver`` operation in `the specification <Generelle egenskaber for
services på sags- og dokumentområdet>`_.
