=============
db-templating
=============

We generate many PostgreSQL files from Jinja2 templates.

To generate the files, you have to run the ``apply-templates.py`` script
located in ``mox/oio_rest/``.

- ``templates/`` contains the jinja2 templates.
- ``../oio_rest/tests/fixtures/generated.sql`` contains an up-to-date
  version of the output.
