#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

SYSTEM_PACKAGES=$(cat "$DIR/SYSTEM_DEPENDENCIES")

for package in "${SYSTEM_PACKAGES[@]}"
do
	sudo apt-get -y install $package
done

# Install pgtap - unit test framework
sudo pgxn install pgtap

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
