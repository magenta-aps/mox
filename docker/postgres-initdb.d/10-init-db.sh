#!/bin/bash
set -e

true "${DB_USER:?DB_USER is unset. Error.}"
true "${DB_PASSWORD:?DB_PASSWORD is unset. Error.}"
true "${DB_NAME:?DB_NAME is unset. Error.}"

# The three following `alter database … set` and `create schema …` commands
# should be identical the ones in oio_rest/oio_rest/db/management.py used for
# tests.

psql -v ON_ERROR_STOP=1 <<-EOSQL
    create user $DB_USER with encrypted password '$DB_PASSWORD';
    create database $DB_NAME;
    grant all privileges on database $DB_NAME to $DB_USER;
    alter database $DB_NAME set search_path to actual_state, public;
    alter database $DB_NAME set datestyle to 'ISO, YMD';
    alter database $DB_NAME set intervalstyle to 'sql_standard';
    \connect $DB_NAME
    create schema actual_state authorization $DB_USER;
EOSQL

# we can connect without password because ``trust`` authentication for Unix
# sockets is enabled inside the container.
