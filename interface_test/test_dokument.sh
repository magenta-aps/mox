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

result=$(curl -s -S -k -X POST \
    -F "json=$(cat $DIR/test_data/dokument_opret.json)" \
    -F "del_indhold1=@$DIR/test_data/test.txt" \
    -F "del_indhold2=@$DIR/test_data/test.docx" \
    -F "del_indhold3=@$DIR/test_data/test.xls" \
    $HOST_URL/dokument/dokument)

uuid=$(echo $result | python3 -c "import json, sys; print(json.load(sys.stdin)['uuid'])")


if [ ! -z "$uuid" ]
then
    printf "\nOprettet dokument: $uuid"
else
    printf "\nOpret dokument fejlet: $result\n"
    exit 1
fi


# Import
import_uuid=$(uuidgen)
curl -s -S -k --output /tmp/dokument_opret.txt -X PUT \
    -F "json=$(cat test_data/dokument_opret.json)" \
    -F 'del_indhold1=@test_data/test.txt' \
    -F 'del_indhold2=@test_data/test.docx' \
    -F 'del_indhold3=@test_data/test.xls' \
    $HOST_URL/dokument/dokument/$import_uuid

printf "\nImported dokument: $import_uuid"


# List
curl -s -S -k -sH "Content-Type: application/json" -X GET $HOST_URL/dokument/dokument?uuid=$uuid > /tmp/listoutput

# Grab the values of the indhold attributes of each DokumentDel, so we know
# the content URLs.
IFS=$'\n' content_paths=($(grep -Po "(?<=store:).+?\.bin" /tmp/listoutput))

# Take only the first one
content_path=${content_paths[0]}

# Try to download the first file
if curl -s -S -k "$HOST_URL/dokument/dokument/$content_path" | grep -q "This is a test"
then
    printf "\nFile upload/download successful"
else
    printf "\nError in file upload/download. Downloaded file does not match uploaded file\n"
    exit 1
fi


# DOESNT ACCEPT variant PARAMETER
# redmine sag #24569

printf "\nWarning: did not run 'search on del relation' test."
# Make sure that deleting DokumentDel relations is possible
#if $(curl -k -H "Content-Type: application/json" \
#"$HOST_URL/dokument/dokument?variant=doc_varianttekst2&deltekst=doc_deltekst2B&underredigeringaf=urn:cpr8883394&uuid=$uuid")
#then
#    printf "\nSearch on del relation successful"
#else
#    printf "\nError in search on del relation.\n"
#    exit 1
#fi


# Update the document
curl -k -sH "Content-Type: application/json" -X PATCH -d "$(cat $DIR/test_data/dokument_opdater.json)" $HOST_URL/dokument/dokument/$uuid > /dev/null

curl -k -sH "Content-Type: application/json" -X GET $HOST_URL/dokument/dokument?uuid=$uuid > /tmp/listoutput


# Try updating, while uploading a new file
curl -k -s -S -X PATCH \
    -F "json=$(cat $DIR/test_data/dokument_opdater2.json)" \
    -F "del_indhold1_opdateret=@$DIR/test_data/test2.txt" \
    $HOST_URL/dokument/dokument/$uuid > /dev/null

# List
curl -k -sH "Content-Type: application/json" -X GET $HOST_URL/dokument/dokument?uuid=$uuid > /tmp/listoutput

# Grab the values of the indhold attributes of each DokumentDel, so we know
# the content URLs.
IFS=$'\n' content_paths=($(grep -Po "(?<=store:).+?\.bin" /tmp/listoutput))
content_path=${content_paths[0]}


# Check that the first DokumentDel file was updated
printf "\nDownloading from $content_path"
if curl -k -s -S "$HOST_URL/dokument/dokument/$content_path" | grep -q "This is an updated test"
then
    printf "\nFile upload/download successful after update operation"
else
    printf "\nError in file upload/download after update operation. Downloaded file does not match uploaded file\n"
    exit 1
fi


# Make sure that deleting DokumentDel relations is possible
if ! $(curl -k -sH "Content-Type: application/json" \
"$HOST_URL/dokument/dokument?variant=doc_varianttekst2&deltekst=doc_deltekst2B&underredigeringaf=urn:cpr8883394&uuid=$uuid" | grep -qi "$uuid")
then
    printf "\nSearch on deleted del relation successful"
else
    printf "\nError in search on deleted del relation.\n"
    exit 1
fi


# Passivate
curl -k -s -S -H "Content-Type: application/json" -X PATCH -d "$(cat $DIR/test_data/facet_passiv.json)" $HOST_URL/dokument/dokument/$uuid > /dev/null


# Delete
curl -k -s -S -H "Content-Type: application/json" -X DELETE -d "$(cat $DIR/test_data/dokument_slet.json)" $HOST_URL/dokument/dokument/$uuid > /dev/null


# Search on the imported dokument
if ! $(curl -k -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?produktion=true&virkningfra=2015-05-20&uuid=$import_uuid" | grep -qi "$import_uuid")
then
    printf "\nSearch 1 successful"
else
    printf "\nError in search 1.\n"
    exit 1
fi


# DOESNT ACCEPT mimetype PARAMETER
# redmine sag #24631

printf "\nWarning: did not run 'search del 1' test."
#if $(curl -k -s -S -H "Content-Type: application/json" "$HOST_URL/dokument/dokument?varianttekst=PDF&deltekst=doc_deltekst1A&mimetype=text/plain&uuid=$import_uuid" | grep -qi "$import_uuid")
#then
#    printf "\nSearch del 1 successful"
#else
#    printf "\nError in search del 1.\n"
#    exit
#fi
#
#if $(curl -k -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?deltekst=doc_deltekst1A&mimetype=text/plain&uuid=$import_uuid" | grep -qi "$import_uuid")
#then
#    printf "\nSearch del 2 successful"
#else
#    printf "\nError in search del 2.\n"
#    exit 1
#fi


if $(curl -k -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?underredigeringaf=urn:cpr8883394&uuid=$import_uuid" | grep -qi "$import_uuid")
then
    printf "\nSearch on del relation URN successful"
else
    printf "\nError in search on del relation URN.\n"
    exit 1
fi



# DOESNT ACCEPT ejer:*objekttype* PARAMETER
# example: ejer:Organsation
# redmine sag: #24634
# should also handle non-existing *objektype*s, as shown in next test.

printf "\nWarning: did not run 'objektype' tests."
#if $(curl -k -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?ejer:Organisation=ef2713ee-1a38-4c23-8fcb-3c4331262194&uuid=$import_uuid" | grep -qi "$import_uuid")
#then
#    printf "\nSearch on relation with objekttype successful"
#else
#    printf "\nError in search on relation with objekttype.\n"
#    exit 1
#fi


#if ! $(curl -k -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?ejer:Blah=ef2713ee-1a38-4c23-8fcb-3c4331262194&uuid=$import_uuid" | grep -qi "$import_uuid")
#then
#    printf "\nSearch on relation with wrong objekttype successful"
#else
#    printf "\nError in search on relation with wrong objekttype.\n"
#    exit 1
#fi


# DOESNT ACCEPT underredigeringaf:*objekttype* PARAMETER
# example: underredigeringaf:Bruger=urn:cpr8883394
# redmine sag: #24635

printf "\nWarning: did not run 'del relation with objekttype' test."
#if $(curl -k -sH "Content-Type: application/json" "$HOST_URL/dokument/dokument?underredigeringaf:Bruger=urn:cpr8883394&uuid=$import_uuid" | grep -qi "$import_uuid")
#then
#    printf "\nSearch on del relation with objekttype successful"
#else
#    printf "\nError in search on del relation with objekttype.\n"
#    exit 1
#fi

echo

