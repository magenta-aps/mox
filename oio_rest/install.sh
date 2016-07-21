#!/bin/bash

DOMAIN="referencedata.dk"
while getopts ":ysd:" OPT; do
  case $OPT in
        s)
                SKIP_SYSTEM_DEPS=1
                ;;
        y)
                ALWAYS_CONFIRM=1
                ;;
        d)
                DOMAIN="$OPTARG"
                ;;
        *)
                echo "Usage: $0 [-y] [-s] [-d domain]"
                echo "  -s: Skip installing oio_rest API system dependencies"
                echo "  -y: Always confirm (yes) when prompted"
				echo "  -d: Specify domain"
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
	SYSTEM_PACKAGES=$(cat "$DIR/SYSTEM_DEPENDENCIES")

	for package in "${SYSTEM_PACKAGES[@]}"; do
		sudo apt-get -y install $package
	done
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

DB_FOLDER="$MOXDIR/db"

source $DB_FOLDER/config.sh

WIPE_DB=0

if [ ! -z $ALWAYS_CONFIRM ]; then
	WIPE_DB=1
else
	if [[ (! -z `command -v psql`) && (! -z `sudo -u postgres psql -Atqc "\list $MOX_DB"`) ]]; then
		echo "Database $MOX_DB already exists in PostgreSQL"
		read -p "Do you want to overwrite it? (y/n): " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			WIPE_DB=1
		fi
	else
		echo "DB does not exist!"
	fi
fi

if [ $WIPE_DB == 1 ]; then
	# Install Database
	source $VIRTUALENV/bin/activate

	echo "Installing database"

	cd "$DB_FOLDER"
	./install.sh
	cd "$DB_FOLDER"
	./recreatedb.sh
	cd "$DIR"
	deactivate
fi


# Install WSGI service
echo "Setting up oio_rest WSGI service for Apache"
sudo mkdir -p /var/www/wsgi
sudo cp --remove-destination "$DIR/server-setup/oio_rest.wsgi" "/var/www/wsgi/"
sudo $MOXDIR/apache/set_include.sh -a "$DIR/server-setup/oio_rest.conf" -l

sudo mkdir -p /var/log/mox/oio_rest

