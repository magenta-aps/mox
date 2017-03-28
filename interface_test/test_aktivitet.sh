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


result=$(curl -k -H "Content-Type: application/json"  -X POST -d "$(cat $DIR/test_data/aktivitet_opret.json)" $HOST_URL/aktivitet/aktivitet)

uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')

if [ ! -z $uuid ]
then
    echo "Oprettet aktivitet: $uuid"
else
    echo "Opret aktivitet fejlet: $result" 
    exit
fi
# Now, import a new aktivitet
# - Suppose no object with this ID exists.
import_uuid=$(uuidgen)
echo "Importerer aktivitet:"
echo ""
curl -k --write-out %{http_code} --output /tmp/aktivitet_opret.txt -sH "Content-Type: application/json"  -X PUT -d "$(cat $DIR/test_data/aktivitet_opret.json)" $HOST_URL/aktivitet/aktivitet/$import_uuid 

echo ""
echo "Done."
# Update the facet

# echo "UPDATE"
curl -k -sH "Content-Type: application/json"  -X PUT -d "$(cat $DIR/test_data/aktivitet_opdater.json)" $HOST_URL/aktivitet/aktivitet/$uuid

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

# curl -k -sH "Content-Type: application/json"  -X GET $HOST_URL/aktivitet/aktivitet/$uuid > /tmp/listoutput



