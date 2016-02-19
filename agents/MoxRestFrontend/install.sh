#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

sudo cp "$DIR/setup/moxrestfrontend.conf" /etc/init/

pushd $DIR
mvn package
popd

sudo mkdir -p /var/log/mox
sudo touch /var/log/mox/moxrestfrontend.log
sudo chown mox /var/log/mox/moxrestfrontend.log

