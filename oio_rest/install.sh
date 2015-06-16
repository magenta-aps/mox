#!/usr/bin/env bash

DIR=$(dirname ${BASH_SOURCE[0]})
VIRTUALENV=./python-env

## System dependencies. These are the packages we need that are not present on a
## fresh Ubuntu install.
#
#SYSTEM_PACKAGES=$(cat "$DIR/doc/SYSTEM_DEPENDENCIES")
#
#for package in "${SYSTEM_PACKAGES[@]}"
#do
#    sudo apt-get -y install $package
#done
#

# Setup virtualenv, install Python packages necessary to run BibOS Admin.

if [ -e $VIRTUALENV/bin/activate ]
then
    echo "virtual environment already installed" 1>&2
else
    virtualenv $VIRTUALENV
fi

source $VIRTUALENV/bin/activate

python ./setup.py develop
