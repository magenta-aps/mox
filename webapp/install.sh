#!/usr/bin/env bash

# TODO: bail if root
UID=`id -u`
if [ $UID == 0 ]; then
	echo "Do not run as root"
	exit 1;
fi

# Ubuntu 14.04 doesn't come with java 8
apt-cache -q=2 show oracle-java8-installer 2>&1 >/dev/null
if [[ $? > 0 ]]; then
	sudo add-apt-repository ppa:webupd8team/java
	sudo apt-get update
	sudo apt-get -y install oracle-java8-installer
fi

SYSTEM_PACKAGES=$(cat "$DIR/SYSTEM_DEPENDENCIES")

for package in "${SYSTEM_PACKAGES[@]}"; do
	sudo apt-get -y install $package
done

