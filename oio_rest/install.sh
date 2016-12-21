#!/bin/bash -e

unset PYTHONPATH

while getopts ":ysd:" OPT; do
  case $OPT in
        s)
                SKIP_SYSTEM_DEPS=1
                ;;
        y)
                ALWAYS_CONFIRM=1
                ;;
        *)
                echo "Usage: $0 [-y] [-s]"
                echo "  -s: Skip installing oio_rest API system dependencies"
                echo "  -y: Always confirm (yes) when prompted"
                exit 1;
                ;;
        esac
done

# Get the folder of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
MOXDIR="$DIR/.."



## System dependencies. These are the packages we need that are not present on a
## fresh OS install.
## Virtualenv is usually among these
#
if [ -z $SKIP_SYSTEM_DEPS ]; then
    echo "Installing oio_rest dependencies"
	sudo apt-get -y install $(cat "$DIR/SYSTEM_DEPENDENCIES")
fi



# Create the MOX content storage directory and give the www-data user ownership
MOX_STORAGE="/var/mox"
echo "Creating MOX content storage directory"
sudo mkdir -p "$MOX_STORAGE"
sudo chown www-data "$MOX_STORAGE"



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
		rm -rf $VIRTUALENV
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
echo "Setting up oio_rest WSGI service for Apache"
sudo mkdir -p /var/www/wsgi
sudo cp --remove-destination "$DIR/server-setup/oio_rest.wsgi" "/var/www/wsgi/"
sudo $MOXDIR/apache/set_include.sh -a "$DIR/server-setup/oio_rest.conf" -l

sudo mkdir -p /var/log/mox/oio_rest

