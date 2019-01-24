.. _API-overview:

========
REST API
========

This page will give you a overview of the REST API. Each of the operations is
describe in general first with special consideration for each object-type
afterwards.


Self-documentation
==================

* On a running LoRa system, it will always be possible to acquire, in JSON, a
  sitemap of valid URLs on ``/site-map/``.

* Similarly, for each service, a JSON representation of the hierarchy's classes
  and their fields may be found at the URL ``/<service>/classes/``. E.g. at
  ``/organisation/classes``.

* Finally a schema for a given object is provided under
  ``/<service>/<object>/schema``. E.g.
  ``/organisation/organisationenhed/schema``


.. caution::

   The structure of each class is not completely analogous to the
   structure of the input JSON as it uses the concept of *"overrides"*.
   This should also be fixed.

.. _API-operations:

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


Document and friends
====================

Document and related objects have some special considerations. They are gathered
here.

.. toctree::
   :maxdepth: 1

   api/advanced/file-operations.rst
   api/advanced/deleting-document.rst


Integrationdata
===============

``integrationdata`` is different and its uniqueness is documented here.

.. toctree::
   :maxdepth: 1

   api/integrationdata.rst
