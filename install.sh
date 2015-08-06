#!/usr/bin/env bash

while getopts ":d" OPT; do
	export DB_INSTALL=1
done

while getopts ":a" OPT; do
	export AGENT_INSTALL=1
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

		# Install pg_amqp - Postgres AMQP extension
		# pg_amqp installs its pg_amqp.so file to the wrong dir on Ubuntu 14.04,
		# e.g. /usr/lib/postgresql/9.3/lib/src, instead of
		# /usr/lib/postgresql/9.3/lib, so we have to move it afterwards

		# Grab the Postgres version number, e.g. 9.3, ignoring the 3rd part
		PG_VERSION_RESULT=$(psql --version)
		PG_VERSION=`expr "$PG_VERSION_RESULT" : '.*\([0-9]\.[0-9]\)\\.[0-9]$'`
		sudo mkdir -p "/usr/lib/postgresql/$PG_VERSION/lib/src"
		sudo pgxn install amqp
		sudo mv "/usr/lib/postgresql/$PG_VERSION/lib/src/pg_amqp.so" "/usr/lib/postgresql/$PG_VERSION/lib/"
		sudo rm -d "/usr/lib/postgresql/$PG_VERSION/lib/src/"


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





	if [ -z $AGENT_INSTALL ]; then

		# Ubuntu 14.04 doesn't come with java 8
		sudo add-apt-repository ppa:webupd8team/java
		sudo apt-get update
		sudo apt-get -y install oracle-java8-installer

		SYSTEM_PACKAGES=$(cat "$DIR/agent/SYSTEM_DEPENDENCIES")
		for package in "${SYSTEM_PACKAGES[@]}"; do
			sudo apt-get -y install $package
		done

		cd $DIR/agent
		mvn package
		

	fi

fi

