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

# Create a Dokument, while simultaneously uploading the file referenced by
# the content field.


# Test configuration
DIR=$(dirname ${BASH_SOURCE[0]})
source $DIR/config.sh

result=$(curl -k -X POST \
    -F "json=$(cat $DIR/test_data/dokument_opret.json)" \
    -F "del_indhold1=@$DIR/test_data/test.txt" \
    -F "del_indhold2=@$DIR/test_data/test.docx" \
    -F "del_indhold3=@$DIR/test_data/test.xls" \
    $HOST_URL/dokument/dokument)
uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')

if [ ! -z $uuid ]
then
    printf "\nOprettet dokument: $uuid"
else
    printf "\nOpret dokument fejlet: $result\n"
    exit
fi

# Import
import_uuid=$(uuidgen)
curl -k --write-out %{http_code} --output /tmp/dokument_opret.txt -X PUT \
    -F "json=$(cat test_data/dokument_opret.json)" \
    -F 'del_indhold1=@test_data/test.txt' \
    -F 'del_indhold2=@test_data/test.docx' \
    -F 'del_indhold3=@test_data/test.xls' \
    $HOST_URL/dokument/dokument/$import_uuid

printf "\nImported dokument: $import_uuid"

# List
curl -k -sH "Content-Type: application/json" -X GET $HOST_URL/dokument/dokument?uuid=$uuid > /tmp/listoutput

# Grab the values of the indhold attributes of each DokumentDel, so we know
# the content URLs.
IFS=$'\n' content_paths=($(sed -n 's/^.*"indhold": "store:\([^"]*\)".*$/\1/p' /tmp/listoutput))

# Take only the first one
content_path=${content_paths[0]}


# Try to download the first file
if curl -k -s "$HOST_URL/dokument/dokument/$content_path" | grep -q "This is a test"
then
    printf "\nFile upload/download successful"
else
    printf "\nError in file upload/download. Downloaded file does not match uploaded file\n"
    exit
fi

# Make sure that deleting DokumentDel relations is possible
if $(curl -k -sH "Content-Type: application/json" \
"$HOST_URL/dokument/dokument?variant=doc_varianttekst2&deltekst=doc_deltekst2B&underredigeringaf=urn:cpr8883394&uuid=$uuid" | grep -qi "$uuid")
then
    printf "\nSearch on del relation successful"
else
    printf "\nError in search on del relation.\n"
    exit
fi

# Update the document
curl -k -sH "Content-Type: application/json" -X PUT -d "$(cat $DIR/test_data/dokument_opdater.json)" $HOST_URL/dokument/dokument/$uuid

curl -k -sH "Content-Type: application/json" -X GET $HOST_URL/dokument/dokument?uuid=$uuid > /tmp/listoutput


# Try updating, while uploading a new file
curl -k -X PUT \
    -F "json=$(cat $DIR/test_data/dokument_opdater2.json)" \
    -F "del_indhold1_opdateret=@$DIR/test_data/test2.txt" \
    $HOST_URL/dokument/dokument/$uuid

# List
curl -k -sH "Content-Type: application/json" -X GET $HOST_URL/dokument/dokument?uuid=$uuid > /tmp/listoutput

# Grab the values of the indhold attributes of each DokumentDel, so we know
# the content URLs.
IFS=$'\n' content_paths=($(sed -n 's/^.*"indhold": "store:\([^"]*\)".*$/\1/p' /tmp/listoutput))
content_path=${content_paths[0]}

printf "\nDownloading from $content_path"

# Check that the first DokumentDel file was updated
if curl -k "$HOST_URL/dokument/dokument/$content_path" | grep -q "This is an updated test"
then
    printf "\nFile upload/download successful after update operation"
else
    printf "\nError in file upload/download after update operation. Downloaded file does not match uploaded file\n"
    exit
fi

# Make sure that deleting DokumentDel relations is possible
if ! $(curl -k -sH "Content-Type: application/json" \
"$HOST_URL/dokument/dokument?variant=doc_varianttekst2&deltekst=doc_deltekst2B&underredigeringaf=urn:cpr8883394&uuid=$uuid" | grep -qi "$uuid")
then
    printf "\nSearch on deleted del relation successful"
else
    printf "\nError in search on deleted del relation.\n"
    exit
fi

# Passivate
curl -k -sH "Content-Type: application/json" -X PUT -d "$(cat $DIR/test_data/facet_passiv.json)" $HOST_URL/dokument/dokument/$uuid

# Delete
curl -k -sH "Content-Type: application/json" -X DELETE -d "$(cat $DIR/test_data/dokument_slet.json)" $HOST_URL/dokument/dokument/$uuid



# Search on the imported dokument

if ! $(curl -k -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?produktion=true&virkningfra=2015-05-20&uuid=$import_uuid" | grep -qi "$import_uuid")
then
    printf "\nSearch 1 successful"
else
    printf "\nError in search 1.\n"
    exit
fi


if $(curl -k -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?varianttekst=PDF&deltekst=doc_deltekst1A&mimetype=text/plain&uuid=$import_uuid" | grep -qi "$import_uuid")
then
    printf "\nSearch del 1 successful"
else
    printf "\nError in search del 1.\n"
    exit
fi

if $(curl -k -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?deltekst=doc_deltekst1A&mimetype=text/plain&uuid=$import_uuid" | grep -qi "$import_uuid")
then
    printf "\nSearch del 2 successful"
else
    printf "\nError in search del 2.\n"
    exit
fi

if $(curl -k -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?underredigeringaf=urn:cpr8883394&uuid=$import_uuid" | grep -qi "$import_uuid")
then
    printf "\nSearch on del relation URN successful"
else
    printf "\nError in search on del relation URN.\n"
    exit
fi


if $(curl -k -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?ejer:Organisation=ef2713ee-1a38-4c23-8fcb-3c4331262194&uuid=$import_uuid" | grep -qi "$import_uuid")
then
    printf "\nSearch on relation with objekttype successful"
else
    printf "\nError in search on relation with objekttype.\n"
    exit
fi

if ! $(curl -k -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?ejer:Blah=ef2713ee-1a38-4c23-8fcb-3c4331262194&uuid=$import_uuid" | grep -qi "$import_uuid")
then
    printf "\nSearch on relation with wrong objekttype successful"
else
    printf "\nError in search on relation with wrong objekttype.\n"
    exit
fi

if $(curl -k -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?underredigeringaf:Bruger=urn:cpr8883394&uuid=$import_uuid" | grep -qi "$import_uuid")
then
    printf "\nSearch on del relation with objekttype successful"
else
    printf "\nError in search on del relation with objekttype.\n"
    exit
fi

echo
