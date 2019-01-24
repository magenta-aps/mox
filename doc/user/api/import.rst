.. _ImportOperation:

----------------
Import operation
----------------

A import operation creates a object similar to a :ref:`CreateOperation`, but you
specify at which UUID. If the UUID of the object does not exist or the object
with that UUID have been :ref:`deleted <DeleteOperation>` or :ref:`passivated
<PassivateOperation>`, a new object is created with the property
``livscykluskode: "Importeret"``.



If a object the UUID `does` exists the import operation completely overwrites
the object and set the property ``livscykluskode: "Rettet"``. This is useful
when you want to change the ``virking``-periods.

The data must contain a complete object in exactly the same format as for the
:ref:`CreateOperation`, but must be :http:method:`PUT` to the objects URL as
given by its UUID.

An example:

.. code-block:: http

    PUT /organisation/organisation/1b1e2de1-6d95-4200-9b60-f85e70cc37cf HTTP/1.1
    Content-Type: application/json

    {
        "attributter": {
            "organisationegenskaber": [
                {
                    "brugervendtnoegle": "magenta-aps",
                    "organisationsnavn": "Magenta ApS",
                    "virkning": {
                        "from": "2017-01-01",
                        "to": "2019-03-14"
                    }
                }
            ]
        },
        "tilstande": {
            "organisationgyldighed": [
                {
                    "gyldighed": "Aktiv",
                    "virkning": {
                        "from": "2017-01-01",
                        "to": "2019-03-14"
                    }
                }
            ]
        }
    }


Known as a ``Importer`` operation in `the specification <Generelle egenskaber for
services på sags- og dokumentområdet>`_.
