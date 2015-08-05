#!/usr/bin/env bash

while getopts ":d" OPT
do
    export DB_INSTALL=1
done

DIR=$(dirname ${BASH_SOURCE[0]})
VIRTUALENV=./python-env

## System dependencies. These are the packages we need that are not present on a
## fresh OS install.
#
SYSTEM_PACKAGES=$(cat "$DIR/doc/SYSTEM_DEPENDENCIES")

for package in "${SYSTEM_PACKAGES[@]}"
do
    sudo apt-get -y install $package
done



if [ -e $VIRTUALENV/bin/activate ]
then
    echo "virtual environment already installed" 1>&2
else
    virtualenv $VIRTUALENV
fi

source $VIRTUALENV/bin/activate

# Database dependencies + installation


# Add system user if none exists
set +x
getent passwd mox
if [ $? -ne 0 ]; then 
    sudo useradd mox
fi

if [ ! -z $DB_INSTALL ]
then
    sudo apt-get install postgresql pgxnclient
    sudo pgxn install pgtap

    # pg_amqp installs to the wrong dir, lib/src, so we have to move it afterwards

    # Grab the Postgres version number, e.g. 9.3, ignoring the 3rd part
    PG_VERSION_RESULT=$(psql --version)
    PG_VERSION=`expr "$PG_VERSION_RESULT" : '.*\([0-9]\.[0-9]\)\\.[0-9]$'`
    sudo mkdir -p "/usr/lib/postgresql/$PG_VERSION/lib/src"
    sudo pgxn install amqp
    sudo mv "/usr/lib/postgresql/$PG_VERSION/lib/src/pg_amqp.so" "/usr/lib/postgresql/$PG_VERSION/lib/"
    sudo rm -d "/usr/lib/postgresql/$PG_VERSION/lib/src/"

    sudo apt-get install postgresql-contrib

    pip install jinja2

    pushd $DIR/../db
    ./recreatedb.sh
    popd

fi

python ./setup.py develop


ln -s $VIRTUALENV/bin/oio_api

 echo "Run ./oio_api to test API"


