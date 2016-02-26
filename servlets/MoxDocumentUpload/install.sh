#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

WARFILE="MoxDocumentUpload.war"

# Compile and install servlet
pushd $DIR
mvn package
popd
if [[ -f "$DIR/target/$WARFILE" ]]; then
	sudo cp "$DIR/target/$WARFILE" "/var/lib/tomcat7/webapps"
fi

