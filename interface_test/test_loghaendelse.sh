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

# First, create a new facet.
set -x
# Test configuration
DIR=$(dirname ${BASH_SOURCE[0]})
source $DIR/config.sh

echo "CREATE"

result=$(curl -k -H "Content-Type: application/json" -X POST -d "$(cat $DIR/test_data/loghaendelse_opret.json)" $HOST_URL/log/loghaendelse)

echo "RESULT: $result"

echo "IMPORT" 

uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')
echo "Oprettet LogHændelse: $uuid"
# Now, import a new facet
# - Suppose no object with this ID exists.
import_uuid=$(uuidgen)


curl -k -sH "Content-Type: application/json" -X PUT -d "$(cat $DIR/test_data/loghaendelse_opdater.json)" $HOST_URL/log/loghaendelse/$uuid

# Delete the LogHændelse. 

echo "DELETE"

curl -k -sH "Content-Type: application/json"  -X DELETE -d "$(cat $DIR/test_data/loghaendelse_slet.json)" $HOST_URL/log/loghaendelse/$uuid


# List loghaendelser

echo "LIST"

curl -k -sH "Content-Type: application/json" -X GET $HOST_URL/log/loghaendelse?uuid=$uuid 

