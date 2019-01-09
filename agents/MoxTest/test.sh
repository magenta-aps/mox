#!/bin/bash
# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


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

