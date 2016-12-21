#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

sudo cp "$DIR/setup/moxrestfrontend.conf" /etc/init/

pushd "$DIR" > /dev/null
mvn package --quiet -Dmaven.test.skip=true > "$DIR/install.log"
popd > /dev/null

sudo mkdir -p /var/log/mox
sudo touch /var/log/mox/moxrestfrontend.log
sudo chown mox /var/log/mox/moxrestfrontend.log

sudo service moxrestfrontend restart
