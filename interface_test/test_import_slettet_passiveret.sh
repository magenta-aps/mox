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

# Create object.

result=$(curl -k -H "Content-Type: application/json" -X POST -d "$(cat $DIR/test_data/facet_opret.json)" $HOST_URL/klassifikation/facet)

uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')

# Passivate object.

 curl -k -sH "Content-Type: application/json" -X PUT -d "$(cat $DIR/test_data/facet_passiv.json)" $HOST_URL/klassifikation/facet/$uuid

 # Import object.

 curl -k -sH "Content-Type: application/json" -X PUT -d "$(cat $DIR/test_data/facet_opret.json)" $HOST_URL/klassifikation/facet/$uuid

 # Delete object

 curl -k -sH "Content-Type: application/json" -X DELETE -d "$(cat $DIR/test_data/facet_slet.json)" $HOST_URL/klassifikation/facet/$uuid


 # Import object
 
 curl -k -sH "Content-Type: application/json" -X PUT -d "$(cat $DIR/test_data/facet_opret.json)" $HOST_URL/klassifikation/facet/$uuid
