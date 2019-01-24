#!/bin/bash -e
# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


set -b
set -x

DIR=${DB_DIR}

test -z "$DIR" && DIR=$(cd $(dirname $0); pwd)
test -z "$BASE_DIR" && BASE_DIR=$(cd $(dirname $DIR); pwd)
test -z "$PYTHON_EXEC" && PYTHON_EXEC=${BASE_DIR}/python-env/bin/python
test -z "$SUPER_USER" && SUPER_USER=postgres
test -z "$MOX_DB" && MOX_DB=mox
test -z "$MOX_DB_USER" && MOX_DB_USER=mox
test -z "$MOX_DB_PASSWORD" && MOX_DB_PASSWORD=mox

MOXDIR="${BASE_DIR}"/oio_rest

cd "$DIR"

PYTHON=${PYTHON_EXEC}

export PGPASSWORD="$MOX_DB_PASSWORD"
# TODO: Support remote $SUPER_USER DB server
#export PGHOST="$MOX_DB_HOST"

sudo -u postgres psql <<EOF
CREATE USER $MOX_DB_USER WITH PASSWORD '$MOX_DB_PASSWORD';
CREATE DATABASE $MOX_DB WITH OWNER '$MOX_DB_USER';
EOF

sudo -u postgres psql -d "$MOX_DB" <<EOF
CREATE SCHEMA actual_state AUTHORIZATION $MOX_DB_USER;
ALTER DATABASE $MOX_DB SET search_path TO actual_state, public;
ALTER DATABASE $MOX_DB SET DATESTYLE to 'ISO, YMD';
ALTER DATABASE $MOX_DB SET INTERVALSTYLE to 'sql_standard';
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA actual_state;
CREATE EXTENSION IF NOT EXISTS "btree_gist" WITH SCHEMA actual_state;
CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA actual_state;
EOF

cd "$MOXDIR"
exec $PYTHON -m oio_rest sql \
    | psql -U "$MOX_DB_USER" -d "$MOX_DB" -h 127.0.0.1 -b -v ON_ERROR_STOP=1
