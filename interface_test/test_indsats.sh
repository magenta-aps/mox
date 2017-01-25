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

# Test configuration
DIR=$(dirname ${BASH_SOURCE[0]})
source $DIR/config.sh


result=$(curl -k -H "Content-Type: application/json"  -X POST -d "$(cat $DIR/test_data/indsats_opret.json)" $HOST_URL/indsats/indsats)

uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')

if [ ! -z $uuid ]
then
    echo "Oprettet indsats: $uuid"
else
    echo "Opret indsats fejlet: $result" 
    exit
fi
# Now, import a new facet
# - Suppose no object with this ID exists.

echo ""
echo "Importing indsats" 

import_uuid=$(uuidgen)

curl -k --write-out %{http_code} --output /tmp/indsats_opret.txt -sH "Content-Type: application/json"  -X PUT -d "$(cat $DIR/test_data/indsats_opret.json)" $HOST_URL/indsats/indsats/$import_uuid 

echo ""
echo "Done"

# Update the facet

# curl -k -sH "Content-Type: application/json"  -X PUT -d "$(cat $DIR/test_data/facet_opdater.json)" $HOST_URL/klassifikation/facet/$uuid

# Passivate the facet. 

# curl -k -sH "Content-Type: application/json"  -X PUT -d "$(cat $DIR/test_data/facet_passiv.json)" $HOST_URL/klassifikation/facet/$uuid

# Delete the facet. 

# curl -k -sH "Content-Type: application/json"  -X DELETE -d "$(cat $DIR/test_data/facet_slet.json)" $HOST_URL/klassifikation/facet/$uuid

# NOTE: The difference between import and update&passive hinges on
# whether the object with the given UUID exists or not.
#
# The difference between update and passive hinges on whether a life
# cycle code is supplied directly in the input or not.


# List aktiviteter

curl -k -sH "Content-Type: application/json"  -X GET $HOST_URL/klassifikation/facet?uuid=$uuid > /tmp/listoutput



