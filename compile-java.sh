#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

FOLDERS="modules/agent modules/json modules/spreadsheet agents/MoxTabel agents/MoxRestFrontend servlets/MoxDocumentUpload"
for FOLDER in $FOLDERS; do
	pushd "$DIR/$FOLDER" > /dev/null
	./install.sh
	popd > /dev/null
done
