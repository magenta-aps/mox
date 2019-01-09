#!/bin/bash -e
# Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
MOXDIR=$( cd "$DIR/../.." && pwd )

mvn package --quiet -f "$DIR/pom.xml" -Dmaven.test.skip=true -Dmaven.clean.skip=true

sudo mkdir -p /var/log/mox
sudo touch /var/log/mox/moxtest.log
sudo chown mox:mox /var/log/mox/moxtest.log

