#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})
PRECMD=""
if [[ `whoami` ne "mox" ]]; then
    PRECMD="sudo su mox "
fi

cd $DIR
$PRECMD java -cp "target/MoxTabel-1.0.jar:target/dependency/*" dk.magenta.mox.moxtabel.MoxTabel
cd - > /dev/null
