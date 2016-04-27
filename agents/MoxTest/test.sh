#!/bin/bash
set -x

SELF=${BASH_SOURCE[0]}
DIR=$(dirname "$(test -L "$SELF" && readlink "$SELF" || echo "$SELF")")
COMMAND="java -cp target/MoxTest-1.0.jar:target/dependency/* dk.magenta.mox.test.MoxTest"
AS_USER="mox"

cd $DIR
if [[ `whoami` != "$AS_USER" ]]
then
    echo $AS_USER 
    echo $COMMAND   
    sudo -u $AS_USER $COMMAND
fi

cd - > /dev/null

