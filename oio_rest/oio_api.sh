#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

cd $DIR

VIRTUALENV=../python-env

if [ "x$USER" != "xmox" ]; then
	sudo -u mox $VIRTUALENV/bin/oio_api
else
	$VIRTUALENV/bin/oio_api
fi

cd -
