#!/bin/bash
set -e

true "${DB_NAME:?DB_NAME is unset. Error.}"


# The three following `create extension … ` commands should be identical the
# ones in oio_rest/oio_rest/db/management.py used for tests.

psql -v ON_ERROR_STOP=1 -d $DB_NAME <<-EOSQL
    create extension if not exists "uuid-ossp" with schema actual_state;
    create extension if not exists "btree_gist" with schema actual_state;
    create extension if not exists "pg_trgm" with schema actual_state;
EOSQL

# we can connect without password because ``trust`` authentication for Unix
# sockets is enabled inside the container.
