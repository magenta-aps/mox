#!/bin/bash

source ./config.sh

# Tests must be run as a super user, e.g. the default "postgres" super user.
sudo -u postgres psql -d $MOX_DB -U $MOX_DB_USER -c "SET DateStyle TO 'ISO, MDY';SET INTERVALSTYLE to 'sql_standard';SELECT * FROM runtests ('test'::name);"
