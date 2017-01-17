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

read -p "Install WSO2 identity provider? [N/y] " -r -n 1
echo
if [[ $REPLY != [yY] ]]
then
	USE_WSO2=false
else
	USE_WSO2=true
fi

AMQP_HOST="$DOMAIN"
AMQP_USER="guest"
AMQP_PASS="guest"

REST_HOST="https://$DOMAIN"

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
cp --remove-destination "$MOX_CONFIG.base" "$MOX_CONFIG"

SHELL_CONFIG="$DIR/variables.sh"
cp --remove-destination "$SHELL_CONFIG.base" "$SHELL_CONFIG"

OIO_REST_CONFIG="$DIR/oio_rest/oio_rest/settings.py"
cp --remove-destination "$OIO_REST_CONFIG.base" "$OIO_REST_CONFIG"
sed -i -e s/$\{domain\}/${DOMAIN//\//\\/}/ "$OIO_REST_CONFIG"

APACHE_CONFIG="$DIR/apache/mox.conf"
cp --remove-destination "$APACHE_CONFIG.base" "$APACHE_CONFIG"

# Setup common config
sed -i -e s/$\{domain\}/${DOMAIN//\//\\/}/ "$MOX_CONFIG"

echo "Installing Python"
sudo apt-get -qq update
sudo apt-get -qq install python python-pip python-virtualenv python-jinja2

# Setup apache virtualhost
echo "Setting up Apache virtualhost"
$DIR/apache/install.sh

if $USE_WSO2
then
	echo "Setting up Identity Server"
	$DIR/wso2/install.sh "$DOMAIN"
fi

REINSTALL_VIRTUALENVS=""
read -p "Reinstall python virtual environments [(y)es/(n)o/(A)sk every time] " -r -n 1
echo
if [[ $REPLY == [yY] ]]; then
	REINSTALL_VIRTUALENVS="--overwrite-virtualenv"
elif [[ $REPLY == [nN] ]]; then
	REINSTALL_VIRTUALENVS="--keep-virtualenv"
fi

# Install oio_rest
echo "Installing oio_rest"
echo "$DIR/oio_rest/install.py $REINSTALL_VIRTUALENVS"
$DIR/oio_rest/install.py $REINSTALL_VIRTUALENVS

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
$DIR/agents/MoxTabel/install.py
$DIR/agents/MoxTabel/configure.py --rest-host "$REST_HOST" --amqp-incoming-host "$DOMAIN" --amqp-incoming-user "$AMQP_USER" --amqp-incoming-pass "$AMQP_PASS" --amqp-incoming-exchange "mox.documentconvert" --amqp-outgoing-host "$DOMAIN" --amqp-outgoing-user "$AMQP_USER" --amqp-outgoing-pass "$AMQP_PASS" --amqp-outgoing-exchange "mox.rest"

$DIR/agents/MoxRestFrontend/install.py
$DIR/agents/MoxRestFrontend/configure.py --rest-host "$REST_HOST" --amqp-host "$DOMAIN" --amqp-user "$AMQP_USER" --amqp-pass "$AMQP_PASS" --amqp-exchange "mox.rest"

$DIR/agents/MoxDocumentUpload/install.py $REINSTALL_VIRTUALENVS
$DIR/agents/MoxDocumentUpload/configure.py --rest-host "$REST_HOST" --amqp-host "$DOMAIN" --amqp-user "$AMQP_USER" --amqp-pass "$AMQP_PASS" --amqp-exchange "mox.documentconvert"

$DIR/agents/MoxTest/install.sh

$DIR/agents/MoxDocumentDownload/install.py $REINSTALL_VIRTUALENVS
$DIR/agents/MoxDocumentDownload/configure.py --rest-host "$REST_HOST"

sudo service apache2 reload

echo
echo "Install succeeded!!!"
echo
