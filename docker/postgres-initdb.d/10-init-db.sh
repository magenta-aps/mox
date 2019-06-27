#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 <<-EOSQL
    create user $DB_USER with encrypted password '$DB_PASSWORD';
    create database mox;
    grant all privileges on database mox to $DB_USER;
    alter database mox set search_path to actual_state, public;
    alter database mox set datestyle to 'ISO, YMD';
    alter database mox set intervalstyle to 'sql_standard';
    \connect mox
    create schema actual_state authorization $DB_USER;
EOSQL

# we can connect without password because ``trust`` authentication for Unix
# sockets is enabled inside the container.

# Do not replace this script with a raw .sql script. If an .sql script fails
# (entrypoint script will exit) and the container is restarted with an already
# initialized data directory, the rest of the scripts will not be run.
