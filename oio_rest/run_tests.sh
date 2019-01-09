#!/bin/bash
# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

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

# Execute tests
$PYTHON -m pip install -e .
$PYTHON -m pip install -r requirements-test.txt
$PYTHON -m flake8 --exit-zero
$PYTHON -m pytest
