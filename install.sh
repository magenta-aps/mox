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
## Virtualenv is usually among these
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

if [ ! -d $VIRTUALENV ]; then
	echo "Virtual environment not created!"
else








	# INSTALL DB


	if [ ! -z $DB_INSTALL ]; then
	
		SYSTEM_PACKAGES=$(cat "$DIR/db/SYSTEM_DEPENDENCIES")
		for package in "${SYSTEM_PACKAGES[@]}"; do
			sudo apt-get -y install $package
		done

		source $VIRTUALENV/bin/activate

		sudo pgxn install pgtap
		pip install jinja2
		sudo -u postgres createuser mox

		pushd $DIR/db
		./recreatedb.sh
		popd

		deactivate
	fi

	source $VIRTUALENV/bin/activate

	pushd $DIR/oio_rest
	python setup.py develop
	popd

	deactivate

	echo "Run oio_rest/oio_api.sh to test API"

fi

