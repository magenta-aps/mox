#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

FOLDERS="modules/agent modules/json modules/spreadsheet agents/MoxTabel agents/MoxRestFrontend servlets/MoxDocumentUpload"
for FOLDER in $FOLDERS; do
    ( cd "$DIR/$FOLDER" && ./install.sh )
done
