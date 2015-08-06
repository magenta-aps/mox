#!/usr/bin/env bash

while getopts ":d" OPT
do
    export DB_INSTALL=1
done

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
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

# Database installation


# Add system user if none exists
set +x
getent passwd mox
if [ $? -ne 0 ]; then 
    sudo useradd mox
fi

if [ ! -z $DB_INSTALL ]
then

    # Install and create DB
    # These scripts are very dependent on being inside the db directory

    cd $DIR/../db
    ./install.sh
    cd $DIR/../db
    ./recreatedb.sh
    cd $DIR

fi

python ./setup.py develop


ln -s $VIRTUALENV/bin/oio_api

 echo "Run ./oio_api to test API"


