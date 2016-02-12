#!/usr/bin/env bash

while getopts ":ds" OPT; do
  case $OPT in
  	d)
		DB_INSTALL=1
		;;
	s)
		SKIP_SYSTEM_DEPS=1
		;;
	*)
		echo "Usage: $0 [-d] [-s]"
		echo "	-d: Install and (re-)create the DB"
		echo "	-s: Skip installing oio_rest API system dependencies"
		exit 1;
		;;
	esac
done

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )



# Add system user if none exists
getent passwd mox
if [ $? -ne 0 ]; then 
	echo "Creating system user 'mox'"
	sudo useradd mox
fi



# Install oio_rest
echo "Installing oio_rest"
echo "$DIR/oio_rest/install.sh $@"
$DIR/oio_rest/install.sh "$@"



# Create log dir
echo "Creating log dir"
sudo mkdir -p "/var/log/mox"



echo "Installing java modules"
sudo apt-get -y install maven

$DIR/modules/agent/install.sh
$DIR/modules/auth/install.sh
$DIR/modules/json/install.sh
$DIR/modules/spreadsheet/install.sh

