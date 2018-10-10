#!/bin/bash -e

# If you have been chosen to implement /sag/sag these tests provide
# basic sanity checks. Currently they mainly fail because the
# special sag parameters are being rejected.
# Remember to remove this comment :)


source config.sh
DIR=$(dirname ${BASH_SOURCE[0]})

result=$(curl -k -sH "Content-Type: application/json" -X POST -d "$(cat $DIR/test_data/sag_opret.json)" $HOST_URL/sag/sag)
uuid=$(echo $result | python3 -c "import json, sys; print(json.load(sys.stdin)['uuid'])")
echo "<$uuid>"

if [ ! -z $uuid ]
then
    echo "Oprettet sag: $uuid"
else
    echo "Oprettelse af sag fejlet!\n"
    exit 1
fi


curl -k -sH "Content-Type: application/json" -X GET $HOST_URL/sag/sag?uuid=$uuid > /tmp/list_sag.txt

if $(curl -k -sH "Content-Type: application/json" -X GET "$HOST_URL/sag/sag?andrebehandlere=ef2713ee-1a38-4c23-8fcb-3c4331262194&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case andrebehandlere relation successful"
else
    printf "\nError in search on case andrebehandlere relation\n"
    exit 1
fi


if $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journalpostkode=journalnotat&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case journalpostkode relation successful"
else
    printf "\nError in search on case journalpostkode relation\n"
    exit 1
fi


if ! $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journalpostkode=tilakteretdokument&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case wrong journalpostkode relation successful"
else
    printf "\nError in search on case wrong journalpostkode relation\n"
    exit 1
fi


if $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journalnotat.titel=Kommentarer%&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case journalnotat.titel relation successful"
else
    printf "\nError in search on case journalnotat.titel relation\n"
    exit 1
fi


if ! $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journalnotat.titel=Wrong&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case wrong journalnotat.titel relation successful"
else
    printf "\nError in search on wrong case journalnotat.titel relation\n"
    exit 1
fi


if $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journaldokument.dokumenttitel=Rapport%&uuid=$uuid" |
grep -q "$uuid")
then
    printf "\nSearch on case journaldokument.dokumenttitel relation successful"
else
    printf "\nError in search on case journaldokument.dokumenttitel relation\n"
    exit 1
fi


if ! $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journaldokument.dokumenttitel=Wrong&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case wrong journaldokument.dokumenttitel relation successful"
else
    printf "\nError in search on wrong case journaldokument.dokumenttitel relation\n"
    exit 1
fi


if $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journaldokument.offentlighedundtaget.alternativtitel=Fortroligt!&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case journaldokument.offentlighedundtaget.alternativtitel relation successful"
else
    printf "\nError in search on case journaldokument.offentlighedundtaget.alternativtitel relation\n"
    exit 1
fi


if ! $(curl -k -sH "Content-Type: application/json" -X GET \
"$HOST_URL/sag/sag?journaldokument.offentlighedundtaget.alternativtitel=Wrong&uuid=$uuid" | grep -q "$uuid")
then
    printf "\nSearch on case wrong journaldokument.offentlighedundtaget.alternativtitel relation successful"
else
    printf "\nError in search on case wrong journaldokument.offentlighedundtaget.alternativtitel relation\n"
    exit 1
fi

echo

