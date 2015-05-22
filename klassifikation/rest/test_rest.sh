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

curl -H "Content-Type: application/json" -X POST -d "$(cat test_data/facet_opret.json)" http://127.0.0.1:5000/klassifikation/facet

