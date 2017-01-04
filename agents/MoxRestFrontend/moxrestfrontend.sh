#!/bin/bash -e

DIR=$(cd $(dirname $0); pwd)
MOXDIR=$(cd "${DIR}/../.."; pwd)

source $MOXDIR/variables.sh

cd $DIR
exec $CMD_JAVA \
    -cp "target/MoxRestFrontend-1.0.jar:target/dependency/*" \
    dk.magenta.mox.moxrestfrontend.MoxRestFrontend \
    --propertiesFile "$MOXDIR/mox.conf" \
    "$DIR/moxrestfrontend.conf"
