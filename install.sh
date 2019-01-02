#!/usr/bin/env sh
# Use install.sh to get a development environment up and running.
# Don't use this in production.

# This script does not automatically install the following components:
#   Mox Rest Frontend, Mox Advis, Mox Elk log

# Furthermore, it does not install rabbitmq or notification-service,
#   based on the assumption that it isn't needed in most development
#   scenarios. An optional flag for that purpose could be added.

set -e

## Check if executed as root
if [ "$( whoami )" == "root" ]; then
    echo "Do not run as root. We'll sudo when necessary";
    exit 1;
fi


# Base directory (current)
BASE_DIR=$(cd "$(dirname $0)"; pwd)


echo "# Installing system dependencies"
echo "## Update system registry"
sudo apt-get -qq update
echo "## Install Python with venv"
sudo apt-get -qy install python3 python3-venv python3-pip python3-dev gcc
sudo apt-get -qy install build-essential libxmlsec1-dev
echo "## Install Postgresql"
sudo apt-get -qy install postgresql postgresql-common postgresql-client \
    postgresql-server-dev-all postgresql-contrib pgtap


echo "# Create directories"
echo "## Create upload directory"
sudo mkdir /var/mox
sudo chmod 755 /var/mox

echo "## Create log directory"
sudo mkdir /var/log/mox
sudo chmod 755 /var/log/mox

echo "## Create audit log directory"
sudo touch /var/log/mox/audit.log
sudo chmod 644 /var/log/mox/audit.log


echo "# Allow access to postgresql over TCP"
echo "## Update pg_hba.conf"
echo "local all all md5" | sudo tee -a /etc/postgresql/9.5/main/pg_hba.conf > /dev/null
echo "## Apply changes"
sudo service postgresql restart
sudo service postgresql status  # make sure that postgresql is running


echo "# Create virtual environment"
/usr/bin/env python3 -m venv $BASE_DIR/python-env


echo "# Install requirements"
/$BASE_DIR/python-env/bin/pip install -r $BASE_DIR/oio_rest/requirements.txt


echo "# Install oio_rest package"
/$BASE_DIR/python-env/bin/pip install -e $BASE_DIR/oio_rest


echo "# Initialize database"
$BASE_DIR/db/initdb.sh


echo -e "\n# Installation completed successfully."
echo "To activate the oio_rest virtual environment:
    '. $BASE_DIR/python-env/bin/activate'"
echo "When activated, you can start oio_rest:
    'python -m flask run'"
echo "When activated, you can run the test suite:
    'pip install -r $BASE_DIR/oio_rest/requirements-test.txt' once,
    'pytest' from within $BASE_DIR/oio_rest."
echo "To deactivate the oio_rest virtual environment:
    'deactivate'"
