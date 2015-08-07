#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

cd $DIR
java -cp "target/moxagent-1.0.jar:target/dependency/*" dk.magenta.mox.agent.Main listen
cd -
