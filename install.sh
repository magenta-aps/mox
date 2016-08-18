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

ENVIRONMENT=""
while [[ $ENVIRONMENT == "" ]]
do
	echo "Installation type"
	echo "[1] production"
	echo "[2] testing"
	echo "[3] development"
	read -p "Enter type: [1]" -n 1 -r
	echo
	if [[ $REPLY =~ ^[1]$ ]]; then
		ENVIRONMENT="production"
	elif [[ $REPLY =~ ^[2]$ ]]; then
		ENVIRONMENT="testing"
	elif [[ $REPLY =~ ^[3]$ ]]; then
		ENVIRONMENT="development"
	fi
done

# Add system user if none exists
getent passwd mox
if [ $? -ne 0 ]; then 
	echo "Creating system user 'mox'"
	sudo useradd mox
fi

# Setup symlinks
./setsymlinks.sh $ENVIRONMENT

# Install oio_rest
echo "Installing oio_rest"
echo "$DIR/oio_rest/install.sh $@"
$DIR/oio_rest/install.sh "$@"



# Create log dir
echo "Creating log dir"
sudo mkdir -p "/var/log/mox"

JAVA_HIGHEST_VERSION=0
JAVA_VERSION_NEEDED=8
regex=".*/java-([0-9]+).*"
files=`find /usr/lib -wholename '*/bin/javac' -perm -a=x -type f`
for f in $files; do
	if [[ $f =~ $regex ]]; then
		version="${BASH_REMATCH[1]}"
		if [[ $version > $JAVA_HIGHEST_VERSION ]]; then
			JAVA_HIGHEST_VERSION=$version
		fi
    fi
done
if [ $JAVA_HIGHEST_VERSION -ge $JAVA_VERSION_NEEDED ]; then
	echo "Java is installed in version $JAVA_HIGHEST_VERSION"
else
	echo "Installing java in version $JAVA_VERSION_NEEDED"
	sudo apt-cache -q=2 show "openjdk-$JAVA_VERSION_NEEDED-jdk" 2> /dev/null 1> /dev/null
	if [[ $? > 0 ]]; then
		# openjdk is not available in the version we want
		sudo add-apt-repository ppa:openjdk-r/ppa
		sudo apt-get update > /dev/null
	fi
	sudo apt-get --yes --quiet install "openjdk-$JAVA_VERSION_NEEDED-jdk"
	sudo update-alternatives --set javac /usr/lib/jvm/java-8-openjdk-amd64/bin/javac
fi

echo "Installing java modules"
sudo apt-get -y install maven


$DIR/modules/json/install.sh
$DIR/modules/agent/install.sh
$DIR/modules/auth/install.sh
$DIR/modules/spreadsheet/install.sh


sudo mkdir -p "/var/log/mox"


echo "Installing Tomcat webservices"
$DIR/servlets/install.sh



$DIR/servlets/MoxDocumentUpload/install.sh
$DIR/agents/MoxTabel/install.sh
$DIR/agents/MoxRestFrontend/install.sh
$DIR/agents/MoxTest/install.sh

sudo chown -R mox:mox $DIR

