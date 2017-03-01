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

# First, create a new itsystem

# Test configuration
DIR=$(dirname ${BASH_SOURCE[0]})
source $DIR/config.sh

result=$(curl -k -H "Content-Type: application/json" -X POST -d "$(cat $DIR/test_data/itsystem_opret.json)" $HOST_URL/organisation/itsystem)
uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')
echo "Oprettet itsystem: $uuid"

#exit

#curl -k -sH "Content-Type: application/json" -X PUT -d "$(cat $DIR/test_data/klasse_opdater.json)" http://127.0.0.1:5000/klassifikation/klasse/$uuid



# List klasser

#curl -k -sH "Content-Type: application/json" -X GET http://127.0.0.1:5000/klassifikation/klasse?uuid=$uuid 

