#!/bin/bash

echo "Compiling auth module"
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOTDIR="/srv/mox"

SYSTEM_PACKAGES=$(cat "$DIR/SYSTEM_DEPENDENCIES")
for package in "${SYSTEM_PACKAGES[@]}"; do
	sudo apt-get -y install $package
done

pushd "$DIR" > /dev/null
mvn package --quiet -Dmaven.test.skip=true
popd > /dev/null

if [ ! -f "$DIR/auth.properties" ]; then
	ln -s "$DIR/auth.properties.production" "$DIR/auth.properties"
fi

ln -sf "$DIR/auth.sh" "$ROOTDIR/auth.sh"

LOGFILE="/var/log/mox/auth.log"
sudo touch $LOGFILE
sudo chown mox $LOGFILE
sudo chmod 664 $LOGFILE

