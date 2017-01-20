#!/usr/bin/env bash

echo "Compiling baseagent module"
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
pushd "$DIR" > /dev/null

mvn package --quiet -Dmaven.test.skip=true -Dmaven.clean.skip=true
mvn org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file --quiet -Dfile=target/agent-1.0.jar -DgroupId=dk.magenta.mox -DartifactId=agent -Dversion=1.0 -Dpackaging=jar -DlocalRepositoryPath=$HOME/.m2/repository

popd > /dev/null

