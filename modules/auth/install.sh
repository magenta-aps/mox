#!/bin/bash

echo "Compiling auth module"
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOTDIR="/srv/mox"
WSO2DIR="/opt/wso2is-5.0.0"
WSO2KEYSTORENAME="newkeystore.jks"

SYSTEM_PACKAGES=$(cat "$DIR/SYSTEM_DEPENDENCIES")
for package in "${SYSTEM_PACKAGES[@]}"; do
	sudo apt-get --yes --quiet install $package
done

pushd "$DIR" > /dev/null
mvn package --quiet -Dmaven.test.skip=true
popd > /dev/null

ln --symbolic --force "$WSO2DIR/repository/resources/security/$WSO2KEYSTORENAME" "$DIR/wso2keystore.jks"

ln --symbolic --force "$DIR/auth.sh" "$ROOTDIR/auth.sh"

LOGFILE="/var/log/mox/auth.log"
sudo touch $LOGFILE
sudo chown mox $LOGFILE
sudo chmod 664 $LOGFILE

