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

# First, create a new Sag

# Test configuration
source config.sh
DIR=$(dirname ${BASH_SOURCE[0]})

result=$(curl -k -sH "Content-Type: application/json" -X POST -d "$(cat $DIR/test_data/sag_opret.json)" $HOST_URL/sag/sag)
echo "<$result>"
uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')
if [ ! -z $uuid ]
then
    echo "Oprettet sag: $uuid"
else
    echo "Oprettelse af sag fejlet!\n"
    exit
fi
# Later, test import etc.
# - Suppose no object with this ID exists.
#import_uuid=$(uuidgen)

# List Sag
echo "List, output til /tmp/list_sag.txt"

#set -x
curl -k -sH "Content-Type: application/json" -X GET $HOST_URL/sag/sag?uuid=$uuid > /tmp/list_sag.txt
#set +x

if $(curl -k -sH "Content-Type: application/json" -X GET "$HOST_URL/sag/sag?andrebehandlere=ef2713ee-1a38-4c23-8fcb-3c4331262194&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case andrebehandlere relation successful"
else
    printf "\nError in search on case andrebehandlere relation\n"
    exit
fi




if $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journalpostkode=journalnotat&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case journalpostkode relation successful"
else
    printf "\nError in search on case journalpostkode relation\n"
    exit
fi

if ! $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journalpostkode=tilakteretdokument&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case wrong journalpostkode relation successful"
else
    printf "\nError in search on case wrong journalpostkode relation\n"
    exit
fi

if $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journalnotat.titel=Kommentarer%&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case journalnotat.titel relation successful"
else
    printf "\nError in search on case journalnotat.titel relation\n"
    exit
fi

if ! $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journalnotat.titel=Wrong&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case wrong journalnotat.titel relation successful"
else
    printf "\nError in search on wrong case journalnotat.titel relation\n"
    exit
fi

if $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journaldokument.dokumenttitel=Rapport%&uuid=$uuid" |
grep -q "$uuid")
then
    printf "\nSearch on case journaldokument.dokumenttitel relation successful"
else
    printf "\nError in search on case journaldokument.dokumenttitel relation\n"
    exit
fi

if ! $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journaldokument.dokumenttitel=Wrong&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case wrong journaldokument.dokumenttitel relation successful"
else
    printf "\nError in search on wrong case journaldokument.dokumenttitel relation\n"
    exit
fi

if $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journaldokument.offentlighedundtaget.alternativtitel=Fortroligt!&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case journaldokument.offentlighedundtaget.alternativtitel relation successful"
else
    printf "\nError in search on case journaldokument.offentlighedundtaget.alternativtitel relation\n"
    exit
fi

if ! $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journaldokument.offentlighedundtaget.alternativtitel=Wrong&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case wrong journaldokument.offentlighedundtaget.alternativtitel relation successful"
else
    printf "\nError in search on case wrong journaldokument.offentlighedundtaget.alternativtitel relation\n"
    exit
fi

echo
