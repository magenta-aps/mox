#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

SYSTEM_PACKAGES=$(cat "$DIR/SYSTEM_DEPENDENCIES")

for package in "${SYSTEM_PACKAGES[@]}"; do
	sudo apt-get -y install $package
done




# Install Tomcat apache connector
SERVERNAME="moxdev.magenta-aps.dk"
REPLACENAME="moxtest.magenta-aps.dk"

echo "Setting up Tomcat connector for Apache"

sudo cp "$DIR/server-setup/tomcat.conf" "/etc/apache2/sites-available/"
sed -i "s/$REPLACENAME/$SERVERNAME/" "/etc/apache2/sites-available/tomcat.conf"
sudo a2ensite tomcat

