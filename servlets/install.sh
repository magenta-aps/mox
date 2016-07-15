#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
MOXDIR="$DIR/.."

JAVA_HOME="/usr/lib/jvm/java-8-oracle"

SYSTEM_PACKAGES=$(cat "$DIR/SYSTEM_DEPENDENCIES")

for package in "${SYSTEM_PACKAGES[@]}"; do
	sudo apt-get -y install $package
done

# Fix erroneous tomcat library path
sudo ln -sf /var/lib/tomcat7/common/ /usr/share/tomcat7/
sudo ln -sf /var/lib/tomcat7/server/ /usr/share/tomcat7/
sudo ln -sf /var/lib/tomcat7/shared/ /usr/share/tomcat7/

WORKERS_CONFIG="/etc/libapache2-mod-jk/workers.properties"
sudo sed -i -r "s/workers.tomcat_home=.*/workers.tomcat_home=\/usr\/share\/tomcat7/" $WORKERS_CONFIG
sudo service tomcat7 restart

sudo $MOXDIR/apache/set_include.sh -a "$DIR/moxdocumentupload.conf"

