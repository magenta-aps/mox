#!/bin/bash -e
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

MOXDIR=${BASE_DIR}/oio_rest

cd $DIR

PYTHON=${PYTHON_EXEC}

export PGPASSWORD="$MOX_DB_PASSWORD"
# TODO: Support remote $SUPER_USER DB server
#export PGHOST="$MOX_DB_HOST"

sudo -u postgres psql <<EOF
CREATE USER $MOX_DB_USER WITH PASSWORD '$MOX_DB_PASSWORD';
CREATE DATABASE $MOX_DB WITH OWNER '$MOX_DB_USER';
EOF

cd $MOXDIR
exec $PYTHON -m oio_rest.db_templating \
    | sudo -u postgres psql -v ON_ERROR_STOP=1 -d $MOX_DB
