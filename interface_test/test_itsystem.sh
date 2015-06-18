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

# First, create a new itsystem

result=$(curl -H "Content-Type: application/json" -X POST -d "$(cat test_data/itsystem_opret.json)" http://127.0.0.1:5000/organisation/itsystem)
uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')
echo "Oprettet itsystem: $uuid"

#exit

#curl -sH "Content-Type: application/json" -X PUT -d "$(cat test_data/klasse_opdater.json)" http://127.0.0.1:5000/klassifikation/klasse/$uuid



# List klasser

#curl -sH "Content-Type: application/json" -X GET http://127.0.0.1:5000/klassifikation/klasse?uuid=$uuid 

