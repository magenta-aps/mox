#!/usr/bin/env bash

mvn package
mvn org.apache.maven.plugins:maven-install-plugin:2.5.2:install-file -Dfile=target/agent-1.0.jar -DgroupId=dk.magenta.mox -DartifactId=agent -Dversion=1.0 -Dpackaging=jar -DlocalRepositoryPath=$HOME/.m2/repository
