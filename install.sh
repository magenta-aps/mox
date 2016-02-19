#!/usr/bin/env bash

# TODO: bail if root
if [ `id -u` == 0 ]; then
	echo "Do not run as root. We'll sudo when necessary"
	exit 1;
fi


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
echo "DIR=$DIR"



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



# Ubuntu 14.04 doesn't come with java 8
sudo apt-cache -q=2 show oracle-java8-installer 2>&1 >/dev/null
if [[ $? > 0 ]]; then
	sudo add-apt-repository ppa:webupd8team/java
	sudo apt-get update
	sudo apt-get -y install oracle-java8-installer
fi
export JAVA_HOME="/usr/lib/jvm/java-8-oracle/"

echo "Installing java modules"
sudo apt-get -y install maven


$DIR/modules/agent/install.sh
$DIR/modules/auth/install.sh
$DIR/modules/json/install.sh
$DIR/modules/spreadsheet/install.sh



echo "Installing Tomcat webservices"
$DIR/webapp/install.sh



$DIR/agents/MoxTabel/install.sh
$DIR/agents/MoxRestFrontend/install.sh

