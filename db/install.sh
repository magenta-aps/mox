#!/bin/bash

if [ `id -u` != "0" ]; then
	echo "You must run this script as root"
else
	DIR=$(dirname ${BASH_SOURCE[0]})

	SYSTEM_PACKAGES=$(cat "$DIR/SYSTEM_DEPENDENCIES")

	for package in "${SYSTEM_PACKAGES[@]}"
	do
		sudo apt-get -y install $package
	done

fi
