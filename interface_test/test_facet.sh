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

# First, create a new facet.

# Test configuration
DIR=$(dirname ${BASH_SOURCE[0]})
source $DIR/config.sh

if [ -z $AUTH_TOKEN ]
then
    AUTH_TOKEN=$(${DIR}/../auth.sh --insecure)
    if [ -z $AUTH_TOKEN ]
    then
         AUTH="-H \"Authorization: -z $AUTH_TOKEN\""
    fi
fi

result=$(curl -k -H "Content-Type: application/json" -X POST -d "$(cat $DIR/test_data/facet_opret.json)" $HOST_URL/klassifikation/facet)

uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')

if [ ! -z $uuid ]
then
    echo "Oprettet facet: $uuid"
else
    echo "Opret facet fejlet: $result" 
    exit
fi
# Now, import a new facet
# - Suppose no object with this ID exists.
import_uuid=$(uuidgen)

curl -k --write-out %{http_code} --output /tmp/facet_opret.txt -sH "Content-Type: application/json" $AUTH -X PUT -d "$(cat $DIR/test_data/facet_opret.json)" $HOST_URL/klassifikation/facet/$import_uuid 

# Update the facet

curl -k -sH "Content-Type: application/json" $AUTH -X PUT -d "$(cat $DIR/test_data/facet_opdater.json)" $HOST_URL/klassifikation/facet/$uuid

# Passivate the facet. 

curl -k -sH "Content-Type: application/json"  $AUTH -X PUT -d "$(cat $DIR/test_data/facet_passiv.json)" $HOST_URL/klassifikation/facet/$uuid

# Delete the facet. 

curl -k -sH "Content-Type: application/json"  $AUTH -X DELETE -d "$(cat $DIR/test_data/facet_slet.json)" $HOST_URL/klassifikation/facet/$uuid

# NOTE: The difference between import and update&passive hinges on
# whether the object with the given UUID exists or not.
#
# The difference between update and passive hinges on whether a life
# cycle code is supplied directly in the input or not.


# List facets

curl -k -sH "Content-Type: application/json"  $AUTH -X GET $HOST_URL/klassifikation/facet?uuid=$uuid > /tmp/listoutput

# Search

curl -k -sH "Content-Type: application/json"   $AUTH -X GET "$HOST_URL/klassifikation/facet?redaktoerer=ddc99abd-c1b0-48c2-aef7-74fea841adae&redaktoerer=ef2713ee-1a38-4c23-8fcb-3c4331262194&status=Publiceret&brugervendtnoegle=ORGFUNK&plan=XYZ"

curl -k -sH "Content-Type: application/json"   $AUTH -X GET "$HOST_URL/klassifikation/facet?redaktoerer=ddc99abd-c1b0-48c2-aef7-74fea841adae&redaktoerer=ef2713ee-1a38-4c23-8fcb-3c4331262194&status=Publiceret&brugervendtnoegle=ORGFUNK&plan=XYZ&virkningFra=2000-01-01&virkningTil=2005-01-01"

curl -k -sH "Content-Type: application/json"  $AUTH -X GET "$HOST_URL/klassifikation/facet?redaktoerer=ddc99abd-c1b0-48c2-aef7-74fea841adae&redaktoerer=ef2713ee-1a38-4c23-8fcb-3c4331262194&status=Publiceret&brugervendtnoegle=ORGFUNK&plan=XYZ&virkningFra=2016-01-01&virkningTil=2018-01-01"

curl -k -sH "Content-Type: application/json"  $AUTH -X GET "$HOST_URL/klassifikation/facet?livscykluskode=Opstaaet&registreretFra=2016-01-01"

curl -k -sH "Content-Type: application/json"  $AUTH -X GET "$HOST_URL/klassifikation/facet?vilkaarligAttr=%funktion"

curl -k -sH "Content-Type: application/json"  $AUTH -X GET "$HOST_URL/klassifikation/facet?vilkaarligRel=ddc99abd-c1b0-48c2-aef7-74fea841adae"

