#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})
COMMAND="java -cp target/MoxTest-1.0.jar:target/dependency/* dk.magenta.mox.test.MoxTest"
AS_USER="mox"

$COMMAND

