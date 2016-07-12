#!/usr/bin/env bash

echo "Compiling json module"
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
pushd "$DIR" > /dev/null

mvn package --quiet -Dmaven.test.skip=true
mvn org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file --quiet -Dfile=target/json-1.0.jar -DgroupId=dk.magenta.mox -DartifactId=json -Dversion=1.0 -Dpackaging=jar -DlocalRepositoryPath=$HOME/.m2/repository

popd > /dev/null

