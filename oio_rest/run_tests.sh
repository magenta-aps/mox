#!/bin/bash

set -ex

cd $(dirname $0)

# Virtualenv / Python
TEST_ENV=/tmp/python-test
PYTHON=${TEST_ENV}/bin/python

# Create virtualenv
python -m virtualenv --quiet $TEST_ENV

# Temporary workaround
# These variables are needed to run $ROOT/db/mkdb.sh
export SUPER_USER="postgres"
export MOX_DB="mox"
export MOX_DB_USER="mox"
export MOX_DB_PASSWORD="mox"

export MOX_AMQP_HOST="localhost"
export MOX_AMQP_PORT=5672
export MOX_AMQP_USER="guest"
export MOX_AMQP_PASS="guest"
export MOX_AMQP_VHOST="/"

# Install common lib
$PYTHON -m pip install -e ../lib/common

# Execute tests
$PYTHON -m pip install -r requirements-test.txt
$PYTHON -m flake8 --exit-zero
$PYTHON -m pytest
