#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

cd $DIR
java -cp "target/MoxTabel-1.0.jar:target/dependency/*" dk.magenta.mox.moxtabel.MoxTabel
cd - > /dev/null
