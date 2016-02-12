#!/bin/bash

SERVERNAME="moxdev.magenta-aps.dk"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "Setting up oio_rest WSGI service for Apache"
sudo mkdir -p /var/www/wsgi
sudo cp "$DIR/server-setup/oio_rest.wsgi" "/var/www/wsgi/"

sudo cp "$DIR/server-setup/oio_rest.conf" "/etc/apache2/sites-available/"
sudo a2ensite oio_rest

REPLACENAME="moxtest.magenta-aps.dk"
sed -i "s/$REPLACENAME/$SERVERNAME" "$DIR/oio_rest/settings.py"

