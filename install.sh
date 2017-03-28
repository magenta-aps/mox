#!/bin/bash -e

# TODO: bail if root
if [ `id -u` == 0 ]; then
	echo "Do not run as root. We'll sudo when necessary"
	exit 1;
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Query for hostname
DOMAIN=$(hostname --fqdn)

read -p "Host name: [$DOMAIN] " -r
echo
if [[ "x$REPLY" != "x" ]]; then
	DOMAIN="$REPLY"
fi

# Add system user if none exists
if ! getent passwd mox > /dev/null
then
	echo "Creating system user 'mox'"
	sudo useradd --system -s /usr/sbin/nologin -d /srv/mox mox
fi

# Create log dir
echo "Creating log dir"
sudo mkdir -p "/var/log/mox"

# Config files that may be altered during install should be copied from git, but not themselves be present there
MOX_CONFIG="$DIR/mox.conf"
if test -f "$MOX_CONFIG"
then
    echo "Not overwriting $MOX_CONFIG"
else
    cp --remove-destination "$MOX_CONFIG.base" "$MOX_CONFIG"
    sed -i -e s/$\{domain\}/${DOMAIN//\//\\/}/ "$MOX_CONFIG"
fi

SHELL_CONFIG="$DIR/variables.sh"
if test -f "$SHELL_CONFIG"
then
    echo "Not overwriting $SHELL_CONFIG"
else
    cp --remove-destination "$SHELL_CONFIG.base" "$SHELL_CONFIG"
fi

OIO_REST_CONFIG="$DIR/oio_rest/oio_rest/settings.py"
if test -f "$OIO_REST_CONFIG"
then
    echo "Not overwriting $OIO_REST_CONFIG"
else
    cp --remove-destination "$OIO_REST_CONFIG.base" "$OIO_REST_CONFIG"
    sed -i -e s/$\{domain\}/${DOMAIN//\//\\/}/ "$OIO_REST_CONFIG"
fi

echo "Installing Python"
sudo apt-get -qq update
sudo apt-get -qq install python python-pip python-virtualenv python-jinja2

# Setup apache virtualhost
echo "Setting up Apache virtualhost"
$DIR/apache/install.py -d "$DOMAIN"

# Install oio_rest
echo "Installing oio_rest"
echo "$DIR/oio_rest/install.py"
$DIR/oio_rest/install.py

# Install database
echo "Installing database"
echo "$DIR/db/install.sh"
$DIR/db/install.sh

$DIR/install/install_java.sh 8

# Install Maven
echo "Installing Maven"
sudo apt-get -qq install maven

# Compile modules
echo "Installing java modules"
$DIR/agentbase/java/install.sh

echo "$DIR/agentbase/python/mox" > "$DIR/agentbase/python/mox/mox.pth"

# Compile agents
echo "Installing Agents"
$DIR/agents/install.sh "$DOMAIN"
$DIR/python_agents/install.py

echo
echo "Install succeeded!!!"
echo
