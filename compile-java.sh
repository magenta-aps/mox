#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

FOLDERS="modules/agent modules/json modules/spreadsheet agents/MoxTabel agents/MoxRestFrontend webapp"
for FOLDER in $FOLDERS; do
	pushd "$DIR/$FOLDER"
	./install.sh
	popd
done

if [[ -f "$DIR/target/mox.war" ]]; then
	sudo cp "$DIR/target/mox.war" "/var/lib/tomcat7/webapps"
fi

