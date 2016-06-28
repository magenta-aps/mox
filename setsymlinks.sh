#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


ENVIRONMENT=$1

ln -sf "$DIR/modules/auth/auth.sh" "$DIR/auth.sh"

if [ "x$ENVIRONMENT" != "x" ]; then
	if [ $1 == "--help" ]; then
		echo "Usage: $0 [production|testing|development]"
	elif [ $ENVIRONMENT == "development" -o $ENVIRONMENT == "testing" -o $ENVIRONMENT == "production" ]; then
		ln -sf "$DIR/oio_rest/oio_rest/settings.py.$ENVIRONMENT" "$DIR/oio_rest/oio_rest/settings.py"
		ln -sf "$DIR/servlets/MoxDocumentUpload/web/WEB-INF/web.xml.$ENVIRONMENT" "$DIR/servlets/MoxDocumentUpload/web/WEB-INF/web.xml"
		# sudo ln -sf "$DIR/servlets/server-setup/tomcat.conf.$ENVIRONMENT" "/etc/apache2/sites-available/tomcat.conf"
		sudo ln -sf "$DIR/oio_rest/server-setup/oio_rest.conf.$ENVIRONMENT" "/etc/apache2/sites-available/oio_rest.conf"
	else
		echo "Please specify either 'production', 'testing' or 'development'"
	fi
fi

