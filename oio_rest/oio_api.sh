#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

cd $DIR

VIRTUALENV=../python-env

if [ "x$USER" != "xmox" ]; then
	exec sudo -u mox $VIRTUALENV/bin/oio_api "$@"
else
	exec $VIRTUALENV/bin/oio_api "$@"
fi
