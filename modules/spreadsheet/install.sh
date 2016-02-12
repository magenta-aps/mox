#!/usr/bin/env bash

echo "Compiling spreadsheet module"
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
pushd "$DIR"

mvn package
mvn org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=target/spreadsheet-1.0.jar -DgroupId=dk.magenta.mox -DartifactId=spreadsheet -Dversion=1.0 -Dpackaging=jar -DlocalRepositoryPath=$HOME/.m2/repository

popd
