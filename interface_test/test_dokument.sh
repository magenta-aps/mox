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
    -F "json=$(cat test_data/dokument_opret.json)" \
    -F 'del_indhold1=@test_data/test.txt' \
    -F 'del_indhold2=@test_data/test.docx' \
    -F 'del_indhold3=@test_data/test.xls' \
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

# Grab the values of the indhold attributes of each DokumentDel, so we know
# the content URLs.
IFS=$'\n' content_paths=($(grep -Po '(?<="indhold": "store:)[^"]*(?=")' /tmp/listoutput))

# Take only the first one
content_path=${content_paths[0]}


# Try to download the first file
if curl "http://127.0.0.1:5000/dokument/dokument/$content_path" | grep -q "This is a test"
then
    echo "File upload/download successful"
else
    echo "Error in file upload/download. Downloaded file does not match uploaded file"
fi

# Update the document
curl -sH "Content-Type: application/json" -X PUT -d "$(cat test_data/dokument_opdater.json)" http://127.0.0.1:5000/dokument/dokument/$uuid

curl -sH "Content-Type: application/json" -X GET http://127.0.0.1:5000/dokument/dokument?uuid=$uuid > /tmp/listoutput


# Try updating, while uploading a new file
curl -X PUT \
    -F "json=$(cat test_data/dokument_opdater2.json)" \
    -F 'del_indhold1_opdateret=@test_data/test2.txt' \
    http://localhost:5000/dokument/dokument/$uuid

# List
curl -sH "Content-Type: application/json" -X GET http://127.0.0.1:5000/dokument/dokument?uuid=$uuid > /tmp/listoutput

# Grab the values of the indhold attributes of each DokumentDel, so we know
# the content URLs.
IFS=$'\n' content_paths=($(grep -Po '(?<="indhold": "store:)[^"]*(?=")' /tmp/listoutput))
content_path=${content_paths[0]}

echo "Downloading from $content_path"

# Check that the first DokumentDel file was updated
if curl "http://127.0.0.1:5000/dokument/dokument/$content_path" | grep -q "This is an updated test"
then
    echo "File upload/download successful after update operation"
else
    echo "Error in file upload/download after update operation. Downloaded file does not match uploaded file"
fi

curl -sH "Content-Type: application/json" -X DELETE -d "$(cat test_data/dokument_slet.json)" http://127.0.0.1:5000/dokument/dokument/$uuid