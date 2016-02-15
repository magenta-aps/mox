#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

if [[ -z $@ ]]; then
  args="listen"
else
  args="$@"
fi


cd $DIR
java -cp "target/MoxRestFrontend-1.0.jar:target/dependency/*" dk.magenta.mox.moxrestfrontend.MoxRestFrontend $args
cd - > /dev/null
