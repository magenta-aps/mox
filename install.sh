#!/usr/bin/env bash

while getopts ":d" OPT; do
	export DB_INSTALL=1
done

DIR=$(dirname ${BASH_SOURCE[0]})


# Add system user if none exists
set +x
getent passwd mox
if [ $? -ne 0 ]; then 
	sudo useradd mox
fi



# INSTALL OIO_REST


## System dependencies. These are the packages we need that are not present on a
## fresh OS install.
#
SYSTEM_PACKAGES=$(cat "$DIR/oio_rest/SYSTEM_DEPENDENCIES")

for package in "${SYSTEM_PACKAGES[@]}"; do
	sudo apt-get -y install $package
done






# Setup and start virtual environment
VIRTUALENV=oio_rest/python-env

if [ -d $VIRTUALENV ]; then
	rm -rf $VIRTUALENV
fi

virtualenv $VIRTUALENV

source $VIRTUALENV/bin/activate

# Database dependencies + installation

if [ ! -z $DB_INSTALL ]; then
	# INSTALL DB

	SYSTEM_PACKAGES=$(cat "$DIR/db/SYSTEM_DEPENDENCIES")
	for package in "${SYSTEM_PACKAGES[@]}"; do
		sudo apt-get -y install $package
	done

	sudo pgxn install pgtap
	pip install jinja2
	sudo -u postgres createuser mox

	pushd $DIR/db
	./recreatedb.sh
	popd
fi




pushd $DIR/oio_rest
sudo python ./setup.py develop
popd

echo "Run oio_rest/oio_api.sh to test API"


