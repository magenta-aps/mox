.. _API-integrationdata:

===============
Integrationdata
===============

``integrationsdata`` is a regular text field intended for information from
extern systems so they can be kept in sync. This field should only include
values that do not belong in another field. Do not overuse it. It is not part
of the OIO standard.


Usage
=========

The intention is that ``integrationsdata`` always contains a JSON-valid piece
of text. Applications that use the field should parse it as JSON and send valid
JSON in return.

.. warning::

   When you want to add or update a field in ``integrationsdata``, please make
   sure to send all the existing fields along, so they are not accidentally
   removed.  This is easy to mess up, so take care.

.. code-block:: json
   :caption: A small ``organisation`` with ``integrationsdata``.
   :emphasize-lines: 10

   {
     "attributter": {
       "organisationegenskaber": [{
         "brugervendtnoegle": "magenta-aps",
         "organisationsnavn": "Magenta ApS",
         "virkning": {
           "from": "2017-01-01",
           "to": "2019-03-14"
         },
         "integrationsdata": "{\"sdløn\": \"id5402349\", \"IB\": 4}"
       }]
     },
     "tilstande": {
       "organisationgyldighed": [{
         "gyldighed": "Aktiv",
         "virkning": {
           "from": "2017-01-01",
           "to": "2019-03-14"
         }
       }
     ]}
   }

Notice that the quotes (``"``) in ``integrationsdata`` have been escaped as
``\"``.
