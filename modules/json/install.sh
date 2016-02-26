#!/usr/bin/env bash

echo "Compiling json module"
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
pushd "$DIR"

mvn package
mvn org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=target/json-1.0.jar -DgroupId=dk.magenta.mox -DartifactId=json -Dversion=1.0 -Dpackaging=jar -DlocalRepositoryPath=$HOME/.m2/repository

popd

