#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

sudo cp "$DIR/setup/moxrestfrontend.conf" /etc/init/

pushd "$DIR" > /dev/null
mvn package --quiet -Dmaven.test.skip=true
popd > /dev/null

sudo mkdir -p /var/log/mox
sudo touch /var/log/mox/moxrestfrontend.log
sudo chown mox /var/log/mox/moxrestfrontend.log

PROPERTIESFILENAME="moxrestfrontend.properties"

if [ ! -f "$DIR/$PROPERTIESFILENAME" ]; then
	ln -s "$DIR/$PROPERTIESFILENAME.production" "$DIR/$PROPERTIESFILENAME"
fi

sudo service moxrestfrontend restart
