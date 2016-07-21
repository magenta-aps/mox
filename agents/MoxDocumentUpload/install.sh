#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
MOXDIR="$DIR/../.."

# Setup and start virtual environment
VIRTUALENV="$DIR/python-env"

CREATE_VIRTUALENV=0

if [ -d $VIRTUALENV ]; then
	if [ -z $ALWAYS_CONFIRM ]; then
		echo "$VIRTUALENV already existed."
		read -p "Do you want to reinstall it? (y/n): " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			CREATE_VIRTUALENV=1
		else
			CREATE_VIRTUALENV=0
		fi
	else
		CREATE_VIRTUALENV=1
	fi
	if [ $CREATE_VIRTUALENV == 1 ]; then
		rm --recursive --force $VIRTUALENV
	fi
else
	CREATE_VIRTUALENV=1
fi

if [ $CREATE_VIRTUALENV == 1 ]; then
	echo "Creating virtual enviroment '$VIRTUALENV'"
	virtualenv $VIRTUALENV

	if [ ! -d $VIRTUALENV ]; then
		echo "Failed creating virtual environment!"
		exit 1
	else
		echo "Virtual environment created. Starting..."
		source $VIRTUALENV/bin/activate

		pushd "$DIR"
		python setup.py develop
		popd

		echo "Stopping virtual environment"
		deactivate
	fi
fi

# Install WSGI service
echo "Setting up moxdocumentupload WSGI service for Apache"
sudo mkdir --parents /var/www/wsgi
sudo cp --remove-destination "$DIR/setup/moxdocumentupload.wsgi" "/var/www/wsgi/"
sudo $MOXDIR/apache/set_include.sh -a "$DIR/setup/moxdocumentupload.conf"

