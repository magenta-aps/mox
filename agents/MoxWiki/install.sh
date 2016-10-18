#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
MOXDIR="$DIR/../.."
MODULES_BASE="$MOXDIR/modules/python"

# Setup and start virtual environment
VIRTUALENV="$DIR/python-env"

CREATE_VIRTUALENV=0

if [ -d $VIRTUALENV ]; then
	if [ -z $ALWAYS_CONFIRM ]; then
		echo "$VIRTUALENV already exists."
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
		ln --symbolic $MODULES_BASE/mox $VIRTUALENV/local/mox
		popd

		echo "Stopping virtual environment"
		deactivate
	fi
fi
