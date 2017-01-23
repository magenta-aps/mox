#!/bin/bash -e

DIR=$(cd $(dirname $0); pwd)
MOXDIR=$(cd "${DIR}/../.."; pwd)

source $MOXDIR/variables.sh

cd "$DIR"

exec $CMD_JAVA -Xmx4g \
     -cp target/MoxTabel-1.0.jar:target/dependency/* \
     dk.magenta.mox.moxtabel.MoxTabel
