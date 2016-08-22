#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

WARNAME="MoxDocumentUpload"
WARFILE="$WARNAME.war"

sudo mkdir -p /var/log/mox
sudo touch /var/log/mox/moxdocumentupload.log
sudo chown tomcat7 /var/log/mox/moxdocumentupload.log

# Compile and install servlet
pushd "$DIR" > /dev/null
mvn package --quiet -Dmaven.test.skip=true
popd > /dev/null

CONFIGFILENAME="web/WEB-INF/web.xml"
DOMAIN=$1

cp --remove-destination "$DIR/$CONFIGFILENAME.base" "$DIR/$CONFIGFILENAME"
sed -i -e s/$\{domain\}/${DOMAIN//\//\\/}/ "$DIR/$CONFIGFILENAME"

if [[ -f "$DIR/target/$WARFILE" ]]; then
    if [[ "x$WARNAME" != "x" && -d "/var/lib/tomcat7/webapps/$WARNAME" ]]; then
        sudo rm -r "/var/lib/tomcat7/webapps/$WARNAME"
    fi
    if [[ "x$WARNAME" != "x" && -f "/var/lib/tomcat7/webapps/$WARFILE" ]]; then
        sudo rm "/var/lib/tomcat7/webapps/$WARFILE"
    fi
	sudo cp "$DIR/target/$WARFILE" "/var/lib/tomcat7/webapps"
	sudo cp $DIR/target/$WARNAME/WEB-INF/lib/*.jar "/var/lib/tomcat7/lib/mox/"
fi
