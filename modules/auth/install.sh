#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Ubuntu 14.04 doesn't come with java 8
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get -y install oracle-java8-installer

SYSTEM_PACKAGES=$(cat "$DIR/SYSTEM_DEPENDENCIES")
for package in "${SYSTEM_PACKAGES[@]}"; do
	sudo apt-get -y install $package
done

cd $DIR
mvn package

cd "../../"
ln -s "modules/auth/auth.sh" "auth.sh"

