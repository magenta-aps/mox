#!/usr/bin/env bash


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
set -x

sudo apt-get install postgresql pgxnclient
sudo pgxn install pgtap
sudo apt-get install postgresql-contrib

pip install jinja2

pushd $DIR/../db
./recreatedb.sh
popd


python ./setup.py develop


ln -s $VIRTUALENV/bin/oio_api

 echo "Run ./oio_api to test API"


