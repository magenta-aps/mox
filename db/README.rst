db/
===

This folder contains the code for initializing the underlying database
for lora.


Testing
=======

You can run the database tests with the following command::
    $ pg_prove --dbname mox --username mox --runtests --schema test

The tests are run by Jenkins.

The tests are written in `PL/pgSQL` and located in `tests/`. They are
written in the `pgTAP` framework. More info can be found at
https://pgtap.org and http://testanything.org.
