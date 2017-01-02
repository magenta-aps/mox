#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
MOXDIR=$( cd "$DIR/../.." && pwd )

(
    cd "$DIR"
    mvn package -Dmaven.test.skip=true > "$DIR/install.log"
)

if ! id moxrestfrontend > /dev/null 2>&1
then
    sudo useradd --system -s /usr/sbin/nologin -g mox moxrestfrontend
fi

tempfile=$(mktemp -t moxrestfrontend.XXXXX)

sed -e "s,/srv/mox,$MOXDIR," \
    "$DIR/setup/moxrestfrontend.conf" \
    > $tempfile
sudo install -m 644 $tempfile /etc/init/moxrestfrontend.conf
rm $tempfile

sudo touch /var/log/mox/moxrestfrontend.log
sudo chown moxrestfrontend:mox /var/log/mox/moxrestfrontend.log

sudo service moxrestfrontend restart
