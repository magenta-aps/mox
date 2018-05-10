#!/bin/bash

# Temporary workaround
# These variables are needed to run this test
export SUPER_USER="postgres"
export MOX_DB="mox"
export MOX_DB_USER="mox"
export MOX_DB_PASSWORD="mox"

export MOX_AMQP_HOST="localhost"
export MOX_AMQP_PORT=5672
export MOX_AMQP_USER="guest"
export MOX_AMQP_PASS="guest"
export MOX_AMQP_VHOST="/"


# Tests must be run as a super user, e.g. the default "postgres" super user.
sudo -u postgres psql -d $MOX_DB -U $MOX_DB_USER -c "SET DateStyle TO 'ISO, MDY';SET INTERVALSTYLE to 'sql_standard';SELECT * FROM runtests ('test'::name);"
