#!/bin/bash

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

# Get the folder of this script
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "DIR=$DIR"



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



# Create the MOX content storage directory and give the mox user ownership
MOX_STORAGE="/var/mox"
echo "Creating MOX content storage directory"
sudo mkdir -p "$MOX_STORAGE"
sudo chown mox "$MOX_STORAGE"



# Setup and start virtual environment
VIRTUALENV="$DIR/python-env"

echo "Setting up virtual enviroment '$VIRTUALENV'"
if [ -d $VIRTUALENV ]; then
	echo "$VIRTUALENV already existed. Removing."
	rm -rf $VIRTUALENV
fi

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



# Install Database
if [ ! -z $DB_INSTALL ]; then
	source $VIRTUALENV/bin/activate
	DB_FOLDER="$DIR/../db"

	echo "Installing database dependencies"
	SYSTEM_PACKAGES=$(cat "$DB_FOLDER/SYSTEM_DEPENDENCIES")
	for package in "${SYSTEM_PACKAGES[@]}"; do
		sudo apt-get -y install $package
	done

	echo "Installing database"

	cd "$DB_FOLDER"
	./install.sh
	cd "$DB_FOLDER"
	./recreatedb.sh
	cd "$DIR"
	deactivate
fi



# Install WSGI service
SERVERNAME="moxdev.magenta-aps.dk"

echo "Setting up oio_rest WSGI service for Apache"
sudo mkdir -p /var/www/wsgi
sudo cp "$DIR/server-setup/oio_rest.wsgi" "/var/www/wsgi/"

sudo cp "$DIR/server-setup/oio_rest.conf" "/etc/apache2/sites-available/"
sudo a2ensite oio_rest

REPLACENAME="moxtest.magenta-aps.dk"
sed -i "s/$REPLACENAME/$SERVERNAME/" "$DIR/oio_rest/settings.py"

