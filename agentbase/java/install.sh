#!/usr/bin/env bash
# Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


echo "Compiling baseagent module"
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
pushd "$DIR" > /dev/null

mvn package --quiet -Dmaven.test.skip=true -Dmaven.clean.skip=true
mvn org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file --quiet -Dfile=target/agent-1.0.jar -DgroupId=dk.magenta.mox -DartifactId=agent -Dversion=1.0 -Dpackaging=jar -DlocalRepositoryPath=$HOME/.m2/repository

popd > /dev/null

