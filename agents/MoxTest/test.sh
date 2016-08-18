#!/bin/bash

SELF=${BASH_SOURCE[0]}
DIR=$(dirname "$(test -L "$SELF" && readlink "$SELF" || echo "$SELF")")
MOXDIR="$DIR/../.."
source $MOXDIR/variables.sh
COMMAND="$CMD_JAVA -cp target/MoxTest-1.0.jar:target/dependency/* dk.magenta.mox.test.MoxTest"
AS_USER="mox"

cd $DIR
if [[ `whoami` != "$AS_USER" ]]
then
    sudo -u $AS_USER $COMMAND
else
    $COMMAND
fi

cd - > /dev/null

