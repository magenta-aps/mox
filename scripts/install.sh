#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
MOXDIR="$DIR/.."

sudo $MOXDIR/apache/set_include.sh -a "$DIR/server-setup/moxscripts.conf"
sudo a2enmod cgi

