#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})
COMMAND="java -cp target/MoxTabel-1.0.jar:target/dependency/* -DpropertiesFile=/srv/mox/mox.conf dk.magenta.mox.moxtabel.MoxTabel"
AS_USER="mox"

cd $DIR
if [[ `whoami` != "$AS_USER" ]]; then
    sudo su $AS_USER -c "$COMMAND"
else
    $COMMAND
fi
cd - > /dev/null
