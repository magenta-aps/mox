#!/bin/bash

# Please keep this in sync with ``doc/user/database.rst`` :-)

set -e

true "${DB_USER:?DB_USER is unset. Error!}"
true "${DB_PASSWORD:?DB_PASSWORD is unset. Error!}"
true "${DB_NAME:?DB_NAME is unset. Error!}"

psql -v ON_ERROR_STOP=1 <<-EOSQL
    create user $DB_USER with encrypted password '$DB_PASSWORD';
    create database $DB_NAME;
    grant all privileges on database $DB_NAME to $DB_USER;
    \connect $DB_NAME
    create schema actual_state authorization $DB_USER;
EOSQL

# we can connect without password because ``trust`` authentication for Unix
# sockets is enabled inside the container.
