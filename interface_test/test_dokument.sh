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

# Create a Dokument, while simultaneously uploading the file referenced by
# the content field.
result=$(curl -X POST \
    -F "json=$(cat test_data/dokument_opret.json);type=application/json" \
    -F 'del_indhold1=@test_data/facet_opret.json' \
    -F 'del_indhold2=@test_data/facet_opdater.json' \
    -F 'del_indhold3=@test_data/facet_slet.json' \
    http://localhost:5000/dokument/dokument)
uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')

if [ ! -z $uuid ]
then
    echo "Oprettet dokument: $uuid"
else
    echo "Opret dokument fejlet: $uuid"
    exit
fi

# List
curl -sH "Content-Type: application/json" -X GET http://127.0.0.1:5000/dokument/dokument?uuid=$uuid > /tmp/listoutput
