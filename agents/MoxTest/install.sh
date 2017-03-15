#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
MOXDIR=$( cd "$DIR/../.." && pwd )

mvn package --quiet -f "$DIR/pom.xml" -Dmaven.test.skip=true -Dmaven.clean.skip=true

sudo mkdir -p /var/log/mox
sudo touch /var/log/mox/moxtest.log
sudo chown mox:mox /var/log/mox/moxtest.log

