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

HOST_URL="https://mox.magenta-aps.dk"

read -p "Indtast URL, default $HOST_URL: " URL

if [ ! -z $URL ]
then
    HOST_URL=$URL
fi


DIR=$(dirname ${BASH_SOURCE[0]})
result=$(curl -H "Content-Type: application/json" -X POST -d "$(cat $DIR/test_data/klasse_opret.json)" $HOST_URL/klassifikation/klasse)
uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')
echo "Oprettet klasse: $uuid"
# Now, import a new facet
# - Suppose no object with this ID exists.
import_uuid=$(uuidgen)

#exit

curl -sH "Content-Type: application/json" -X PUT -d "$(cat $DIR/test_data/klasse_opdater.json)" $HOST_URL/klassifikation/klasse/$uuid



# List klasser

#curl -sH "Content-Type: application/json" -X GET http://127.0.0.1:5000/klassifikation/klasse?uuid=$uuid 

