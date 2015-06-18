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

result=$(curl -H "Content-Type: application/json" -X POST -d "$(cat test_data/facet_opret.json)" http://127.0.0.1:5000/klassifikation/facet)
uuid=$(expr "$result" : '.*"uuid": "\([^"]*\)"')
echo "Oprettet facet: $uuid"
# Now, import a new facet
# - Suppose no object with this ID exists.
import_uuid=$(uuidgen)

curl -sH "Content-Type: application/json" -X PUT -d "$(cat test_data/facet_opret.json)" http://127.0.0.1:5000/klassifikation/facet/$import_uuid 
# Update the facet

curl -sH "Content-Type: application/json" -X PUT -d "$(cat test_data/facet_opdater.json)" http://127.0.0.1:5000/klassifikation/facet/$uuid

# Passivate the facet. 

curl -sH "Content-Type: application/json" -X PUT -d "$(cat test_data/facet_passiv.json)" http://127.0.0.1:5000/klassifikation/facet/$uuid

# Delete the facet. 

curl -sH "Content-Type: application/json" -X DELETE -d "$(cat test_data/facet_slet.json)" http://127.0.0.1:5000/klassifikation/facet/$uuid

# NOTE: The difference between import and update&passive hinges on
# whether the object with the given UUID exists or not.
#
# The difference between update and passive hinges on whether a life
# cycle code is supplied directly in the input or not.


# List facets

curl -sH "Content-Type: application/json" -X GET http://127.0.0.1:5000/klassifikation/facet?uuid=$uuid > /tmp/listoutput

# Search

curl -sH "Content-Type: application/json" -X GET "http://127.0.0.1:5000/klassifikation/facet?redaktoerer=ddc99abd-c1b0-48c2-aef7-74fea841adae&redaktoerer=ef2713ee-1a38-4c23-8fcb-3c4331262194&status=Publiceret&brugervendtnoegle=ORGFUNK&plan=XYZ"

curl -sH "Content-Type: application/json" -X GET "http://127.0.0.1:5000/klassifikation/facet?redaktoerer=ddc99abd-c1b0-48c2-aef7-74fea841adae&redaktoerer=ef2713ee-1a38-4c23-8fcb-3c4331262194&status=Publiceret&brugervendtnoegle=ORGFUNK&plan=XYZ&virkningFra=2000-01-01&virkningTil=2005-01-01"

curl -sH "Content-Type: application/json" -X GET "http://127.0.0.1:5000/klassifikation/facet?redaktoerer=ddc99abd-c1b0-48c2-aef7-74fea841adae&redaktoerer=ef2713ee-1a38-4c23-8fcb-3c4331262194&status=Publiceret&brugervendtnoegle=ORGFUNK&plan=XYZ&virkningFra=2016-01-01&virkningTil=2018-01-01"

curl -sH "Content-Type: application/json" -X GET "http://127.0.0.1:5000/klassifikation/facet?livscykluskode=Opstaaet&registreretFra=2016-01-01"

curl -sH "Content-Type: application/json" -X GET "http://127.0.0.1:5000/klassifikation/facet?vilkaarligAttr=%funktion"

curl -sH "Content-Type: application/json" -X GET "http://127.0.0.1:5000/klassifikation/facet?vilkaarligRel=ddc99abd-c1b0-48c2-aef7-74fea841adae"

