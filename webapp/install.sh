#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

JAVA_HOME="/usr/lib/jvm/java-8-oracle"

SYSTEM_PACKAGES=$(cat "$DIR/SYSTEM_DEPENDENCIES")

for package in "${SYSTEM_PACKAGES[@]}"; do
	sudo apt-get -y install $package
done

# Fix erroneous tomcat library path
sudo ln -s /var/lib/tomcat7/common/ /usr/share/tomcat7/
sudo ln -s /var/lib/tomcat7/server/ /usr/share/tomcat7/
sudo ln -s /var/lib/tomcat7/shared/ /usr/share/tomcat7/

sudo mkdir -p /var/log/mox
sudo touch /var/log/mox/servlet.log
sudo chown tomcat7 /var/log/mox/servlet.log

# Install Tomcat apache connector
SERVERNAME="moxdev.magenta-aps.dk"
REPLACENAME="moxtest.magenta-aps.dk"

echo "Setting up Tomcat connector for Apache"

sudo cp "$DIR/server-setup/tomcat.conf" "/etc/apache2/sites-available/"
sudo sed -i "s/$REPLACENAME/$SERVERNAME/" "/etc/apache2/sites-available/tomcat.conf"
sudo a2ensite tomcat

WORKERS_CONFIG="/etc/libapache2-mod-jk/workers.properties"
sudo sed -i -r "s/workers.tomcat_home=.*/workers.tomcat_home=\/usr\/share\/tomcat7/" $WORKERS_CONFIG
sudo service apache2 reload


# Compile and install servlet
pushd $DIR
mvn package
popd
if [[ -f "$DIR/target/mox.war" ]]; then
	sudo cp "$DIR/target/mox.war" "/var/lib/tomcat7/webapps"
fi

