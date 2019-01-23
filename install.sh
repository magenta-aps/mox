#!/usr/bin/env sh
# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


# Use install.sh to get a development environment up and running.
# Don't use this in production.

# This script does not automatically install the following components:
#   Mox Rest Frontend, Mox Advis, Mox Elk log

# Furthermore, it does not install notification-service, based on the
#   assumption that it isn't needed in most development scenarios. An optional
#   flag for that purpose could be added.

# To get a more complete environment, use `--full`. This will install oio_rest
#   as a service and run nginx and gunicorn all from a seperate user "mox".


set -e


## Check if executed as root
if [ "$( whoami )" = "root" ]; then
    printf "Do not run as root. We'll sudo when necessary\n";
    exit 1;
fi

USER=$(whoami)
if [ "$1" = "--full" ]; then
    FULL=1
    USER="mox"
    sudo useradd --system --password mox -U -s /usr/sbin/nologin mox
else
    FULL=0
fi

# Base directory (current)
BASE_DIR=$(cd "$(dirname $0)"; pwd)


printf "# Installing system dependencies\n"
printf "## Update system registry\n"
sudo apt-get -qq update
printf "## Install Python with venv\n"
sudo apt-get -qy install python3 python3-venv python3-pip libxmlsec1-dev
printf "## Install Postgresql\n"
sudo apt-get -qy install postgresql pgtap
printf "## Install AMQP\n"
sudo apt-get -qy install rabbitmq-server
if [ $FULL -eq 1 ]; then
    printf "## Install nginx\n"
    sudo apt-get -qy install nginx
fi


printf "# Create directories\n"
printf "## Create upload directory\n"
sudo mkdir /var/mox
sudo chown "$USER" /var/mox

printf "## Create log directory\n"
sudo mkdir /var/log/mox
sudo chown "$USER" /var/log/mox

printf "## Create audit log directory\n"
sudo touch /var/log/mox/audit.log
sudo chown "$USER" /var/log/mox/audit.log

printf "# Create virtual environment\n"
/usr/bin/env python3 -m venv $BASE_DIR/python-env


printf "# Install requirements\n"
/$BASE_DIR/python-env/bin/pip install -r $BASE_DIR/oio_rest/requirements.txt


printf "# Install oio_rest package\n"
/$BASE_DIR/python-env/bin/pip install -e $BASE_DIR/oio_rest

if [ $FULL -eq 1 ]; then
    printf "# Install gunicorn\n"
    /$BASE_DIR/python-env/bin/pip install gunicorn
fi


printf "# Initialize database\n"
$BASE_DIR/db/initdb.sh


if [ $FULL -eq 1 ]; then
    printf "# Make oio_rest.service\n"
    printf "
[Unit]
Description=\"MOX OIO Rest Interface\"

[Service]
Type=simple
Restart=on-failure

User=mox
Group=mox

WorkingDirectory=$BASE_DIR
ExecStart=$BASE_DIR/python-env/bin/gunicorn \
    --bind 127.0.0.1:8080 \
    --log-syslog-prefix mox \
    --workers 4 \
    --access-logfile /var/log/mox/oio_access.log \
    --error-logfile /var/log/mox/oio_error.log \
    oio_rest.app:app

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/oio_rest.service > /dev/null
    sudo touch /var/log/mox/oio_access.log
    sudo chown "$USER" /var/log/mox/oio_access.log
    sudo touch /var/log/mox/oio_error.log
    sudo chown "$USER" /var/log/mox/oio_error.log
    printf "
server {
    listen 80;

    # Virtual server name
    server_name _;

    # Do NOT send server details
    server_tokens off;

    # Path to static content
    root /var/www/html;

    # Proxy
    location / {
        # Proxy_pass configuration
        proxy_set_header Connection '';
        chunked_transfer_encoding off;
        proxy_buffering off;
        proxy_cache off;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_http_version 1.1;
        proxy_max_temp_file_size 0;
        proxy_pass http://localhost:8080/;
        proxy_redirect off;
        proxy_read_timeout 240s;
    }
}" | sudo tee /etc/nginx/sites-available/mox > /dev/null
    sudo ln -s /etc/nginx/sites-available/mox /etc/nginx/sites-enabled/mox
    sudo rm /etc/nginx/sites-enabled/default
fi


printf "\n# Installation completed successfully.\n"
if [ $FULL -eq 0 ]; then
    printf "To activate the oio_rest virtual environment:
        '. $BASE_DIR/python-env/bin/activate'\n"
    printf "When activated, you can start oio_rest:
        'python -m flask run'\n"
    printf "When activated, you can run the test suite:
        'pip install -r $BASE_DIR/oio_rest/requirements-test.txt' once,
        'pytest' from within $BASE_DIR/oio_rest.\n"
    printf "To deactivate the oio_rest virtual environment:
        'deactivate'\n"
else
    sudo service oio_rest restart
    sudo service nginx restart
    printf "oio_rest running on localhost\n"
fi
