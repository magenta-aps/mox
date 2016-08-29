#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})
MOXDIR="$DIR/../.."
source $MOXDIR/variables.sh
COMMAND="$CMD_JAVA -Xmx4g -cp target/MoxTabel-1.0.jar:target/dependency/* dk.magenta.mox.moxtabel.MoxTabel --propertiesFile /srv/mox/mox.conf"
AS_USER="mox"

cd $DIR
if [[ `whoami` != "$AS_USER" ]]; then
    sudo su $AS_USER -c "$COMMAND"
else
    $COMMAND
fi
cd - > /dev/null
