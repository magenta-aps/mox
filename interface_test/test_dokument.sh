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

HOST_URL="https://mox.magenta-aps.dk"

read -p "Indtast URL, default $HOST_URL: " URL

if [ ! -z $URL ]
then
    HOST_URL=$URL
fi

result=$(curl -X POST \
    -F "json=$(cat test_data/dokument_opret.json)" \
    -F 'del_indhold1=@test_data/test.txt' \
    -F 'del_indhold2=@test_data/test.docx' \
    -F 'del_indhold3=@test_data/test.xls' \
    $HOST_URL/dokument/dokument)
uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')

if [ ! -z $uuid ]
then
    echo "Oprettet dokument: $uuid"
else
    echo "Opret dokument fejlet: $uuid"
    exit
fi

# Import
import_uuid=$(uuidgen)
curl --write-out %{http_code} --output /tmp/dokument_opret.txt -X PUT \
    -F "json=$(cat test_data/dokument_opret.json)" \
    -F 'del_indhold1=@test_data/test.txt' \
    -F 'del_indhold2=@test_data/test.docx' \
    -F 'del_indhold3=@test_data/test.xls' \
    $HOST_URL/dokument/dokument/$import_uuid

# List
curl -sH "Content-Type: application/json" -X GET $HOST_URL/dokument/dokument?uuid=$uuid > /tmp/listoutput

# Grab the values of the indhold attributes of each DokumentDel, so we know
# the content URLs.
IFS=$'\n' content_paths=($(grep -Po '(?<="indhold": "store:)[^"]*(?=")' /tmp/listoutput))

# Take only the first one
content_path=${content_paths[0]}


# Try to download the first file
if curl "$HOST_URL/dokument/dokument/$content_path" | grep -q "This is a test"
then
    echo "File upload/download successful"
else
    echo "Error in file upload/download. Downloaded file does not match uploaded file"
fi

# Update the document
curl -sH "Content-Type: application/json" -X PUT -d "$(cat test_data/dokument_opdater.json)" $HOST_URL/dokument/dokument/$uuid

curl -sH "Content-Type: application/json" -X GET $HOST_URL/dokument/dokument?uuid=$uuid > /tmp/listoutput


# Try updating, while uploading a new file
curl -X PUT \
    -F "json=$(cat test_data/dokument_opdater2.json)" \
    -F 'del_indhold1_opdateret=@test_data/test2.txt' \
    $HOST_URL/dokument/dokument/$uuid

# List
curl -sH "Content-Type: application/json" -X GET $HOST_URL/dokument/dokument?uuid=$uuid > /tmp/listoutput

# Grab the values of the indhold attributes of each DokumentDel, so we know
# the content URLs.
IFS=$'\n' content_paths=($(grep -Po '(?<="indhold": "store:)[^"]*(?=")' /tmp/listoutput))
content_path=${content_paths[0]}

echo "Downloading from $content_path"

# Check that the first DokumentDel file was updated
if curl "$HOST_URL/dokument/dokument/$content_path" | grep -q "This is an updated test"
then
    echo "File upload/download successful after update operation"
else
    echo "Error in file upload/download after update operation. Downloaded file does not match uploaded file"
fi

# Passivate
curl -sH "Content-Type: application/json" -X PUT -d "$(cat test_data/facet_passiv.json)" $HOST_URL/dokument/dokument/$uuid

# Delete
curl -sH "Content-Type: application/json" -X DELETE -d "$(cat test_data/dokument_slet.json)" $HOST_URL/dokument/dokument/$uuid



# Search on the imported dokument

echo "Search"
curl -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?produktion=true&virkningfra=2015-05-20&uuid=$import_uuid"

# TODO: Test results

echo "Search del"
curl -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?varianttekst=PDF&deltekst=doc_deltekst1A&mimetype=text/plain&uuid=$import_uuid"

# TODO: Test results

