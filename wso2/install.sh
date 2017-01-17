#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DOMAIN=$1

sudo apt-get -y $(cat "$DIR/SYSTEM_DEPENDENCIES")

sudo NODEBUG=1 $DIR/confWSO2cert.sh "$DOMAIN"

sudo service wso2 restart

