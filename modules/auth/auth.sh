#!/bin/bash

# arguments: [-s] [-u username] [-p password] [-i interface] [-f propertiesfile]
# the -s parameter means to silence config output, displaying only the token

SELF=${BASH_SOURCE[0]}
DIR=$(dirname "$(test -L "$SELF" && readlink "$SELF" || echo "$SELF")")
if [[ ! -d "$DIR" ]]; then
	DIR="/srv/mox/modules/auth"
fi

pushd $DIR
java -cp "target/auth-1.0.jar:target/dependency/*" dk.magenta.mox.auth.Main -p "$DIR/auth.properties" -p "/srv/mox/mox.conf" $@
popd

