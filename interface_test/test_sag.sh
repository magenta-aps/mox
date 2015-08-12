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

DIR=$(dirname ${BASH_SOURCE[0]})
result=$(curl -sH "Content-Type: application/json" -X POST -d "$(cat $DIR/test_data/sag_opret.json)" http://127.0.0.1:5000/sag/sag)
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

exit

curl -sH "Content-Type: application/json" -X PUT -d "$(cat test_data/klasse_opdater.json)" http://127.0.0.1:5000/klassifikation/klasse/$uuid



# List klasser

#curl -sH "Content-Type: application/json" -X GET http://127.0.0.1:5000/klassifikation/klasse?uuid=$uuid 

