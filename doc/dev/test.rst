.. _Testing:

Testing
=======

Most test dependencies are installed in the Docker image via
:file:`oio_rest/requirements-test.txt`. The exception is `pgTAP
<https://pgtap.org/>`_ which must be installed in the database. The
:file:`dev-envionment/postgres.Dockerfile` creates a postgres container with
pgTAP.

The tests use the database user credentials defined in :ref:`settings`. It
requires the `CREATEDB
<https://www.postgresql.org/docs/9.6/role-attributes.html>`_ privilege and
`OWNER <https://www.postgresql.org/docs/9.6/sql-alterdatabase.html>`_ of the
database or have the `SUPERUSER
<https://www.postgresql.org/docs/9.6/role-attributes.html>`_ privilege to run
the tests.

The first time a test is run, a database with its name from :ref:`settings`
postfixed with ``_template`` is created. It is used as a template to reset the
database between tests. It is left for the subsequent runs and must be removed
manually if the :ref:`database objects<db_object_init>` change.

When the tests are run, the current database from :ref:`settings` is postfixed
with ``_backup``. After the run it is moved back. It allows you to have data in
the database and still run the test suite.

The docker-compose development environment is setup with the above requirement
and can easily run the tests. See :ref:`Docker-compose-testing`.


Writing new tests
-----------------

The :file:`oio_rest/test/util.py` contains classes suitable for writing tests.
See the docstrings there for determining the proper testclass for your test.

The general naming convention for files containing tests is: if it does not
contain ``integration``, it is not expected to need any external resourses such
as a database.
