#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
MOXDIR=$( cd "$DIR/../.." && pwd )

(
    cd "$DIR"
    mvn package --quiet -Dmaven.test.skip=true
)

sudo mkdir -p /var/log/mox
sudo touch /var/log/mox/moxtest.log
sudo chown mox:mox /var/log/mox/moxtest.log

ln -sf "$DIR/test.sh" "$MOXDIR/test.sh"

