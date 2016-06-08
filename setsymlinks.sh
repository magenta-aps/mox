#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


ENVIRONMENT=$1

ln -sf "$DIR/modules/auth/auth.sh" "$DIR/auth.sh"

if [ "x$ENVIRONMENT" != "x" ]; then
	if [ $1 == "--help" ]; then
		echo "Usage: $0 [production|testing|development]"
	elif [ $ENVIRONMENT == "development" -o $ENVIRONMENT == "testing" -o $ENVIRONMENT == "production" ]; then
		ln -sf "$DIR/agents/MoxRestFrontend/moxrestfrontend.properties.$ENVIRONMENT" "$DIR/agents/MoxRestFrontend/moxrestfrontend.properties"
		ln -sf "$DIR/agents/MoxTabel/moxtabel.properties.$ENVIRONMENT" "$DIR/agents/MoxTabel/moxtabel.properties"
		ln -sf "$DIR/oio_rest/oio_rest/settings.py.$ENVIRONMENT" "$DIR/oio_rest/oio_rest/settings.py"
	else
		echo "Please precify either 'production', 'testing' or 'development'"
	fi
fi

