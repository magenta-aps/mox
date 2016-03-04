#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

JAVA_HOME="/usr/lib/jvm/java-8-oracle"

SYSTEM_PACKAGES=$(cat "$DIR/SYSTEM_DEPENDENCIES")

for package in "${SYSTEM_PACKAGES[@]}"; do
	sudo apt-get -y install $package
done

# Fix erroneous tomcat library path
sudo ln -sf /var/lib/tomcat7/common/ /usr/share/tomcat7/
sudo ln -sf /var/lib/tomcat7/server/ /usr/share/tomcat7/
sudo ln -sf /var/lib/tomcat7/shared/ /usr/share/tomcat7/

# Install Tomcat apache connector
SERVERNAME="moxdev.magenta-aps.dk"
REPLACENAME="moxtest.magenta-aps.dk"

echo "Setting up Tomcat connector for Apache"

if [ ! -f "/etc/apache2/sites-available/tomcat.conf" ]; then
	sudo cp "$DIR/server-setup/tomcat.conf.production" "/etc/apache2/sites-available/tomcat.conf"
fi

sudo a2ensite tomcat

WORKERS_CONFIG="/etc/libapache2-mod-jk/workers.properties"
sudo sed -i -r "s/workers.tomcat_home=.*/workers.tomcat_home=\/usr\/share\/tomcat7/" $WORKERS_CONFIG
sudo service apache2 reload

