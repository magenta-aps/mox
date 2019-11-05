#!/bin/bash
set -e

true "${DB_NAME:?DB_NAME is unset. Error!}"

psql -v ON_ERROR_STOP=1 <<-EOSQL
    alter database $DB_NAME set search_path to actual_state, public;
    alter database $DB_NAME set datestyle to 'ISO, YMD';
    alter database $DB_NAME set intervalstyle to 'sql_standard';
    -- Searching with multiple parameters is faster when these are off.
    -- See #21273 and #23145. It is purely an optimization.
    alter database $DB_NAME set enable_hashagg to off;
    alter database $DB_NAME set enable_sort to off;
EOSQL
