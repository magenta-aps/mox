#!/bin/bash

set -ex

cd $(dirname $0)

# Vars
TEST_ENV=/tmp/python-test
PYTHON_EXEC=${TEST_ENV}/bin/python

# Create virtualenv
python -m virtualenv --quiet $TEST_ENV

# Execute tests
$PYTHON_EXEC -m pip install -r requirements-test.txt
$PYTHON_EXEC -m flake8 --exit-zero
$PYTHON_EXEC -m pytest
