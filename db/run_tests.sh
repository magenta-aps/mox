#!/bin/bash

source ./config.sh

# Tests must be run as a super user, e.g. the default "postgres" super user.
sudo -u postgres psql -d $MOX_DB -U postgres -c "SET DateStyle TO 'ISO, MDY';SELECT * FROM runtests ('test'::name);"
