#!/bin/bash -e
set -x
set -b

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

cd $DIR
source ./config.sh

export PGPASSWORD="$MOX_DB_PASSWORD"
# TODO: Support remote Postgres DB server
#export PGHOST="$MOX_DB_HOST"

sudo -u postgres dropdb --if-exists $MOX_DB
sudo -u postgres dropuser --if-exists $MOX_DB_USER

exec $DIR/initdb.sh
