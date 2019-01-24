.. _UpdateOperation:

----------------
Update operation
----------------

To change an object, issue a :http:method:`PATCH` request containing the JSON
representation of the changes as they apply to the object's attributes, states
and relations. Either directly with the :http:header:`Content-Type` as
``application/json`` as form data with a :http:header:`Content-Type` of
``multipart/form-data`` and a single field, `json`, containing the data.

The :http:method:`PATCH` request must be issued to the object's URL - i.e.,
including the UUID.

An example:

.. code-block:: http

    PATCH /organisation/organisationenhed/862bb783-696d-4345-9f63-cb72ad1736a3 HTTP/1.1
    Content-Type: application/json

    {
        "relationer": {
            "adresser": [
                {
                    "urn": "dawa:0a3f50c4-379f-32b8-e044-0003ba298018",
                    "virkning": {
                        "from": "2018-01-01",
                        "to": "2019-09-01"
                    }
                }
            ]
        }
    }

Alternatively, use a :ref:`ImportOperation` to replace the entire object,
including all ``virkning``-periods.

For the logic of merging see :ref:`API-merging`. To issue a patch that delete
part of an object see :ref:`DeleteAttr`.

Known as a ``Ret`` operation in `the specification <Generelle egenskaber for
services på sags- og dokumentområdet>`_.


.. _AdvUpdateOperation:

.. toctree::
   :caption: Advanced Update
   :glob:

   update/merging.rst
   update/deleting.rst
