#!/bin/bash

# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

set -ex

cd $(dirname $0)

# Virtualenv / Python
TEST_ENV=python-testenv
PYTHON=${TEST_ENV}/bin/python

# Create virtualenv
python3 -m venv $TEST_ENV

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

# Please note that we require a rather recent pip due to our
# use of URL dependencies
$PYTHON -m pip install 'pip>=18.1' 'setuptools>=40'
$PYTHON -m pip install -e '.[tests]'

# Execute tests
$PYTHON -m flake8

FLASK_ENV=testing $PYTHON -m coverage run -m xmlrunner \
        --verbose --buffer --output build/reports "$@"
$PYTHON -m coverage report
$PYTHON -m coverage xml -o build/coverage/coverage.xml
$PYTHON -m coverage html --skip-covered -d build/html
