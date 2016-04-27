#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

pushd $DIR
mvn package
popd

sudo mkdir -p /var/log/mox
sudo touch /var/log/mox/moxtest.log
sudo chown mox:mox /var/log/mox/moxtest.log

ROOTDIR='/srv/mox'
ln -sf "$DIR/test.sh" "$ROOTDIR/test.sh"

