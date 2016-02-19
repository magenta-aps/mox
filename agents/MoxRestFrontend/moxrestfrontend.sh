#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

PRECMD=""
if [[ `whoami` != "mox" ]]; then
    PRECMD="sudo su mox "
fi

cd $DIR
$PRECMD java -cp "target/MoxRestFrontend-1.0.jar:target/dependency/*" dk.magenta.mox.moxrestfrontend.MoxRestFrontend
cd - > /dev/null
