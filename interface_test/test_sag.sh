#!/bin/bash

# In order to start the tests, make sure the REST interface is running.
#
# At present, you do that by activating the virtualenv and running the
# command
#    python app.py
#
# Then run the present script in a different terminal.

# The purpose of these tests is to run through the full CRUD scenario in
# the REST API for all classes in the hierarchy.

# First, create a new Sag

# Test configuration
source config.sh
DIR=$(dirname ${BASH_SOURCE[0]})

result=$(curl -sH "Content-Type: application/json" -X POST -d "$(cat $DIR/test_data/sag_opret.json)" $HOST_URL/sag/sag)
echo "<$result>"
uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')
if [ ! -z $uuid ]
then
    echo "Oprettet sag: $uuid"
else
    echo "Oprettelse af sag fejlet!"
    exit
fi
# Later, test import etc.
# - Suppose no object with this ID exists.
#import_uuid=$(uuidgen)

# List Sag
echo "List, output til /tmp/list_sag.txt"

set -x
curl -sH "Content-Type: application/json" -X GET $HOST_URL/sag/sag?uuid=$uuid > /tmp/list_sag.txt
set +x

