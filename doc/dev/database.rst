Database structure
==================

The `db/` folder contains the SQL source code for initializing the
underlying database for LoRA.


Testing
-------

You can run the database tests with the following command::

    $ pg_prove --dbname mox --username mox --schema test

Alternatively, you can run them within the Python test harness::

    (python-env) $ python -m unittest -vbf tests.test_sql

The tests are written in ``PL/pgSQL`` using the `pgTAP
<https://pgtap.org>`_ framework and located in ``tests/``.

Organisation
------------

The templates are organised as follows:

``basis``
    Initial definitions, structures, extensions, etc.

``funcs/pre``
    Initial function definitions.

``templates``
    The above-mentioned templates specifying core types,
    tables, functions, etc. for each

``funcs/post``
    Function definitions requiring the core tables and types.

``tests``
    The above-mentions PL/pgSQL tests; not loaded into a production
    database.

Templates
---------

We generate many PostgreSQL functions and definitions from Jinja2
templates:

- ``./templates/`` contains the `Jinja2
  <https://palletsprojects.com/p/jinja/>`_ templates.
- ``../oio_rest/tests/fixtures/db-dump.sql`` contains an up-to-date
  version of the output.

After updating the templates, run the tests mentioned above. One of
the tests compares the rendered templates to a fixture, and will fail
if the changes affect the resulting SQL. To fix this, replace the old
results with the new ones::

  $ mv ../oio_rest/tests/fixtures/db-dump.sql.new \
  >    ../oio_rest/tests/fixtures/db-dump.sql

Then, inspect the changes using e.g. ``git diff``.
