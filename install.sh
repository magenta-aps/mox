#!/usr/bin/env bash

while getopts ":d" OPT; do
	export DB_INSTALL=1
done

while getopts ":a" OPT; do
	export AGENT_INSTALL=1
done

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


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

		pip install jinja2
		sudo -u postgres createuser mox

		# Install pgtap - unit test framework
		sudo pgxn install pgtap

		# Install pg_amqp - Postgres AMQP extension
		# We depend on a specific fork, which supports setting of message headers
		# https://github.com/duncanburke/pg_amqp.git
		git clone https://github.com/duncanburke/pg_amqp.git /tmp/pg_amqp
		cd /tmp/pg_amqp && sudo make install
		rm -rf /tmp/pg_amqp

		cd $DIR/db
		./recreatedb.sh
		cd $DIR

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

