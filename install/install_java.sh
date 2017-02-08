#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})
MOXDIR="$DIR/.."
SHELL_CONFIG="$MOXDIR/variables.sh"

JAVA_VERSION_NEEDED="$1"
if [ -z $JAVA_VERSION_NEEDED ]; then
	JAVA_VERSION_NEEDED="8"
elif ! [[ $JAVA_VERSION_NEEDED = *[[:digit:]]* ]]; then
	echo "Invalid major version '$JAVA_VERSION_NEEDED', must be numeric"
	exit 1
fi

JAVA_HIGHEST_VERSION=0
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
	echo "No need to upgrade"
else
	echo "Installing java in version $JAVA_VERSION_NEEDED"
	pkg="openjdk-$JAVA_VERSION_NEEDED-jdk"
	sudo apt-cache -q=2 show $pkg > /dev/null 2>&1
	if [[ $? > 0 ]]; then
		# openjdk is not available in the version we want
        sudo apt-get -qq install software-properties-common
		sudo add-apt-repository -y ppa:openjdk-r/ppa
		sudo apt-get update > /dev/null
	fi
	sudo apt-cache -q=2 show $pkg > /dev/null 2>&1
	if [[ $? > 0 ]]; then
		echo "Java version $JAVA_VERSION_NEEDED is not available"
		exit 1
	fi
	sudo apt-get --yes --quiet install $pkg
    unset pkg
fi

JAVA_VERSION_DIR=""
regex=".*/java-$JAVA_VERSION_NEEDED.*"
files=`find /usr/lib -wholename '*/bin/javac' -perm -a=x -type f`
for f in $files; do
	if [[ $f =~ $regex ]]; then
		JAVA_VERSION_DIR=$(readlink -m "$f/../..")
    fi
done

if [[ "x$JAVA_VERSION_DIR" != "x" ]]; then
	sed -r -e "s|^CMD_JAVA=.*$|CMD_JAVA=$JAVA_VERSION_DIR/bin/java|" \
       -e "s|^CMD_JAVAC=.*$|CMD_JAVAC=$JAVA_VERSION_DIR/bin/javac|" \
       ${SHELL_CONFIG} > ${SHELL_CONFIG}.$$
fi
if [[ -f ${SHELL_CONFIG}.$$ ]]; then
	/bin/mv ${SHELL_CONFIG}.$$ ${SHELL_CONFIG}
fi
