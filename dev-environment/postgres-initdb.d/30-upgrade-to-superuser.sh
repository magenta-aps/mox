#!/bin/bash
set -e

true "${DB_USER:?DB_USER is unset. Error.}"

psql -v ON_ERROR_STOP=1 <<-EOSQL
    ALTER ROLE $DB_USER WITH SUPERUSER;
EOSQL

# we can connect without password because ``trust`` authentication for Unix
# sockets is enabled inside the container.
