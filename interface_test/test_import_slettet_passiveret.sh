#!/bin/bash -e

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
HOST_URL=https://moxtest.magenta-aps.dk
DIR=$(dirname ${BASH_SOURCE[0]})

if [ -z $AUTH_TOKEN ]
then
    echo "Please set authorization header in AUTH_TOKEN"
    exit
fi
# Create object.
set -x
result=$(curl -k -H "Authorization: $AUTH_TOKEN" -H "Content-Type: application/json" -X POST -d "$(cat $DIR/test_data/facet_opret.json)" $HOST_URL/klassifikation/facet)

uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')

# Passivate object.

 curl -k -H "Authorization: $AUTH_TOKEN" -sH "Content-Type: application/json" -X PUT -d "$(cat $DIR/test_data/facet_passiv.json)" $HOST_URL/klassifikation/facet/$uuid

 # Import object.

 curl -k -sH "Content-Type: application/json" -H "Authorization: $AUTH_TOKEN" -X PUT -d "$(cat $DIR/test_data/facet_opret.json)" $HOST_URL/klassifikation/facet/$uuid

 # Delete object

 curl -k -sH "Content-Type: application/json" -H "Authorization: $AUTH_TOKEN" -X DELETE -d "$(cat $DIR/test_data/facet_slet.json)" $HOST_URL/klassifikation/facet/$uuid


 # Import object
 
 curl -k -sH "Content-Type: application/json" -H "Authorization: $AUTH_TOKEN" -X PUT -d "$(cat $DIR/test_data/facet_opret.json)" $HOST_URL/klassifikation/facet/$uuid
