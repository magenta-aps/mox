#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

WARFILE="MoxDocumentUpload.war"

sudo mkdir -p /var/log/mox
sudo touch /var/log/mox/moxdocumentupload.log
sudo chown tomcat7 /var/log/mox/moxdocumentupload.log

# Compile and install servlet
pushd $DIR
mvn package
popd
if [[ -f "$DIR/target/$WARFILE" ]]; then
	sudo cp "$DIR/target/$WARFILE" "/var/lib/tomcat7/webapps"
fi

