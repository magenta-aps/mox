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
    printf "Do not run as root. We'll sudo when necessary\n";
    exit 1;
fi


# Base directory (current)
BASE_DIR=$(cd "$(dirname $0)"; pwd)


printf "# Installing system dependencies\n"
printf "## Update system registry\n"
sudo apt-get -qq update
printf "## Install Python with venv\n"
sudo apt-get -qy install python3 python3-venv python3-pip python3-dev gcc
sudo apt-get -qy install build-essential libxmlsec1-dev
printf "## Install Postgresql\n"
sudo apt-get -qy install postgresql postgresql-common postgresql-client \
    postgresql-server-dev-all postgresql-contrib pgtap
printf "## Install AMQP\n"
sudo apt-get -qy install rabbitmq-server


printf "# Create directories\n"
printf "## Create upload directory\n"
sudo mkdir /var/mox
sudo chmod 755 /var/mox

printf "## Create log directory\n"
sudo mkdir /var/log/mox
sudo chmod 755 /var/log/mox

printf "## Create audit log directory\n"
sudo touch /var/log/mox/audit.log
sudo chmod 644 /var/log/mox/audit.log


printf "# Allow access to postgresql over TCP\n"
printf "## Update pg_hba.conf\n"
printf "local all all md5" | sudo tee -a /etc/postgresql/9.5/main/pg_hba.conf > /dev/null
printf "## Apply changes\n"
sudo service postgresql restart
sudo service postgresql status  # make sure that postgresql is running


printf "# Create virtual environment\n"
/usr/bin/env python3 -m venv $BASE_DIR/python-env


printf "# Install requirements\n"
/$BASE_DIR/python-env/bin/pip install -r $BASE_DIR/oio_rest/requirements.txt


printf "# Install oio_rest package\n"
/$BASE_DIR/python-env/bin/pip install -e $BASE_DIR/oio_rest


printf "# Initialize database\n"
$BASE_DIR/db/initdb.sh


printf "\n# Installation completed successfully.\n"
printf "To activate the oio_rest virtual environment:
    '. $BASE_DIR/python-env/bin/activate'\n"
printf "When activated, you can start oio_rest:
    'python -m flask run'\n"
printf "When activated, you can run the test suite:
    'pip install -r $BASE_DIR/oio_rest/requirements-test.txt' once,
    'pytest' from within $BASE_DIR/oio_rest.\n"
printf "To deactivate the oio_rest virtual environment:
    'deactivate'\n"

