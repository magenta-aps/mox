.. _Database:

========
Database
========

.. todo::

   Document the database in `#30317
   <https://redmine.magenta-aps.dk/issues/30317>`_.


.. _db_user_ext_init:

Database, user and extensions initialization
============================================

``mox`` requires a database and a user in that database. You can configure the
name of the database and user a running ``mox`` will use in :ref:`settings`
under the `[database]` heading. The user should have `all privileges
<https://www.postgresql.org/docs/9.6/sql-grant.html>`_ on the database.
Furthermore, there should be a schema in the database called `actual_state`
that the user has authorization over. At last, the search path should be set to
`"actual_state, public"`. Please refer to the reference script
:file:`docker/postgres-initdb.d/10-init-db.sh`.

There is one more thing ``mox`` needs before it can work with the database:
**extensions**. The required extensions are *uuid-ossp*, *btree_gist* and
*pg_trgm* and they should be created with the schema `actual_state`. Note that
extensions can only be created by a superuser (this is because extensions can
run arbitrary code). Please refer to the reference script
:file:`docker/postgres-initdb.d/20-create-extensions.sh`.



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
