.. _API-overview:

========
REST API
========

This page will give you a overview of the REST API.

.. toctree::
   :caption: Sub pages

   api/self-documentation.rst
   api/tutorial.rst

.. _API-operations:

Time zones
==========

The default timezone for LoRa is UTC. When reading and writing data without a
timezone -- whether it be in the object payloads or as query parameters to the
REST API -- we interpret the given timestamps as UTC time.

.. note::

    We recommend that timezones be added explicitly to every timestamp when
    reading and writing data, to avoid inconsistencies regarding daylight savings
    time.

Operations
==========

.. toctree::
   :maxdepth: 2

   Read <api/read.rst>
   List <api/list.rst>
   Search <api/search.rst>
   Create <api/create.rst>
   Update <api/update.rst>
   Passivate <api/passivate.rst>
   Delete <api/delete.rst>
   Import <api/import.rst>


``Document`` etc.
=================

``Document`` and related objects have some special considerations.

.. toctree::
   :maxdepth: 1

   api/advanced/file-operations.rst
   api/advanced/deleting-document.rst
