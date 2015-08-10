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
curl --trace trace.txt -X POST -F 'json={"content": "field:f1"};type=application/json' -F 'f1=@test_dokument.sh' http://localhost:5000/dokument/dokument