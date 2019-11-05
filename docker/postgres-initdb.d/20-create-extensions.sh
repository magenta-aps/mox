#!/bin/bash

# If you update this script, please reflect the changes in
# ``doc/user/database.rst`` :-)

set -e

true "${DB_NAME:?DB_NAME is unset. Error!}"

psql -v ON_ERROR_STOP=1 -d $DB_NAME <<-EOSQL
    create extension if not exists "uuid-ossp" with schema actual_state;
    create extension if not exists "btree_gist" with schema actual_state;
    create extension if not exists "pg_trgm" with schema actual_state;
EOSQL
