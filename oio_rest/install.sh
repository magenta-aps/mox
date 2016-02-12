#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

SERVERNAME="moxdev.magenta-aps.dk"

sudo mkdir -p /var/www/wsgi
sudo cp "$DIR/server-setup/oio_rest.wsgi" "/var/www/wsgi/"

sudo cp "$DIR/server-setup/oio_rest.conf" "/etc/apache2/sites-available/"
sudo a2ensite oio_rest

REPLACENAME="moxtest.magenta-aps.dk"
sed -i "s/$REPLACENAME/$SERVERNAME" "$DIR/oio_rest/settings.py"

