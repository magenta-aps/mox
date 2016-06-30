#!/usr/bin/env bash

# TODO: bail if root
if [ `id -u` == 0 ]; then
	echo "Do not run as root. We'll sudo when necessary"
	exit 1;
fi

while getopts ":ys" OPT; do
  case $OPT in
	s)
		SKIP_SYSTEM_DEPS=1
		;;
	y)
		ALWAYS_CONFIRM=1
		;;
	*)
		echo "Usage: $0 [-y] [-s]"
		echo "	-s: Skip installing oio_rest API system dependencies"
		echo "	-y: Always confirm (yes) when prompted"
		exit 1;
		;;
	esac
done

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "DIR=$DIR"

DOMAIN="referencedata.dk"
read -p "Domain: [$DOMAIN] " -r
echo
if [[ "x$REPLY" != "x" ]]; then
	DOMAIN="$REPLY"
fi

# Add system user if none exists
getent passwd mox
if [ $? -ne 0 ]; then 
	echo "Creating system user 'mox'"
	sudo useradd mox
fi

CONFIGFILENAME="mox.conf"
# Setup common config
cp --remove-destination "$DIR/$CONFIGFILENAME.base" "$DIR/$CONFIGFILENAME"
sed -i -e s/$\{domain\}/${DOMAIN//\//\\/}/ "$DIR/$CONFIGFILENAME"


# Install oio_rest
echo "Installing oio_rest"
echo "$DIR/oio_rest/install.sh $@"
$DIR/oio_rest/install.sh "$@" -d $DOMAIN



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
sudo ln -sf "/usr/lib/jvm/java-8-oracle/" "/usr/lib/jvm/default-java"

echo "Installing java modules"
sudo apt-get -y install maven


$DIR/modules/json/install.sh
$DIR/modules/agent/install.sh
$DIR/modules/auth/install.sh
$DIR/modules/spreadsheet/install.sh


sudo mkdir -p "/var/log/mox"


echo "Installing Tomcat webservices"
$DIR/servlets/install.sh
$DIR/servlets/MoxDocumentUpload/install.sh "$DOMAIN"

$DIR/agents/MoxTabel/install.sh
$DIR/agents/MoxRestFrontend/install.sh
$DIR/agents/MoxTest/install.sh

sudo chown -R mox:mox $DIR

