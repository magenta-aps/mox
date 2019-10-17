.. _Database:

========
Database
========

.. todo::

   Document the database in `#30317
   <https://redmine.magenta-aps.dk/issues/30317>`_.

.. _db_user_ext_init:

Database, user and extensions initialization
===========================================


.. _db_object_init:

Object initialization
=====================

With mox comes a utility called ``initdb`` that populates a Postgres server
database with all the necessary postgresql objects.

``initdb`` is only intended to run succesfully against a database that has been
initialized as described in :ref:`db_user_ext_init`.

To invoke ``initdb``, run::

    python -m oio_rest initdb

Please also read ``python -m oio_rest initdb --help``.
