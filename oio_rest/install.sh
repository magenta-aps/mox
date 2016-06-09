#!/bin/bash

while getopts ":ds" OPT; do
  case $OPT in
	s)
		SKIP_SYSTEM_DEPS=1
		;;
	*)
		echo "Usage: $0 [-d] [-s]"
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



# Create the MOX content storage directory and give the www-data user ownership
MOX_STORAGE="/var/mox"
echo "Creating MOX content storage directory"
sudo mkdir -p "$MOX_STORAGE"
sudo chown www-data "$MOX_STORAGE"



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

if [ ! -f "$DIR/oio_rest/settings.py" ]; then
	ln -s "$DIR/oio_rest/settings.py.production" "$DIR/oio_rest/settings.py"
fi


WIPE_DB=0
if [[ -z `sudo -u postgres psql -Atqc '\list $MOX_DB'` ]]; then
	echo "Database $MOX_DB already exists in PostgreSQL"
	read -p "Do you want to overwrite it? (y/n): " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		WIPE_DB=1
	fi
fi

if [ $WIPE_DB == 1 ]; then
	# Install Database
	source $VIRTUALENV/bin/activate
	DB_FOLDER="$DIR/../db"

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
sudo cp "$DIR/server-setup/oio_rest.wsgi" "/var/www/wsgi/"

sudo cp "$DIR/server-setup/oio_rest.conf" "/etc/apache2/sites-available/"
sudo a2ensite oio_rest
sudo a2enmod ssl


sudo mkdir -p /var/log/mox/oio_rest

