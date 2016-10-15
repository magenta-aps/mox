#!/bin/bash

source ./config.sh

# Tests must be run as a super user, e.g. the default "postgres" super user.
sudo -u $SUPER_USER psql -d $MOX_DB -U $SUPER_USER  -c "SET DateStyle TO 'ISO, MDY';SELECT * FROM runtests ('test'::name);"
