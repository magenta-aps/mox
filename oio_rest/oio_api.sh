#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

VIRTUALENV=$DIR/python-env

if [ "x$USER" != "xmox" ]; then
	sudo -u mox $VIRTUALENV/bin/oio_api
else
	$VIRTUALENV/bin/oio_api
fi

