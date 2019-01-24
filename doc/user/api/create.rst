.. _CreateOperation:

----------------
Create operation
----------------

To create a new object, :http:method:`POST` the JSON representation of its
attributes, states and relations to the URL of the class. Either directly with
the :http:header:`Content-Type` as ``application/json`` as form data with a
:http:header:`Content-Type` of ``multipart/form-data`` and a single field,
`json`, containing the data.

E.g., to create a new ``organisation``:

.. code-block:: http

    POST /organisation/organisation HTTP/1.1
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


Known as a ``Opret`` operation in `the specification <Generelle egenskaber for
services på sags- og dokumentområdet>`_.
