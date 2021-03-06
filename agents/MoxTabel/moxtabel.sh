#!/bin/bash -e
# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


DIR=$(cd $(dirname $0); pwd)
MOXDIR=$(cd "${DIR}/../.."; pwd)

source $MOXDIR/variables.sh

cd "$DIR"

exec $CMD_JAVA -Xmx4g \
     -cp target/MoxTabel-1.0.jar:target/dependency/* \
     dk.magenta.mox.moxtabel.MoxTabel
