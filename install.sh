#!/bin/bash
# DOES NOT AUTOMATICALLY INSTALL THE FOLLOWING COMPONENTS:
# Mox Rest Frontend, Mox Advis, Mox Elk log

set -e

## Check if executed as root
if [ $( whoami ) == "root" ]; then
    echo "Do not run as root. We'll sudo when necessary"
exit 1;
fi

## Variables

# Base directory (current)
BASE_DIR=$(cd $(dirname $0); pwd)

# Setup directory
INSTALLER_DIR=${BASE_DIR}/installer

# Setup executable
CONFIGURE=${INSTALLER_DIR}/configure.py
INSTALLER=${INSTALLER_DIR}/install_application.py

# Setup requirements
REQUIREMENTS=${INSTALLER_DIR}/install_requirements.txt

# Path to (python) virtual environment
export VIRTUALENV=${BASE_DIR}/python-env

# Path to python executable
export PYTHON_EXEC=${VIRTUALENV}/bin/python

## Install system dependencies
sudo apt-get -qy install python3 python3-venv python3-dev gcc

## Create virtual environment
/usr/bin/env python3 -m venv ${VIRTUALENV}

## Install python (installer) dependencies
$PYTHON_EXEC -m pip install -r $REQUIREMENTS

# Collect info and set information (grains)
$PYTHON_EXEC $CONFIGURE

## Run installer (as SUPERUSER)
sudo $PYTHON_EXEC $INSTALLER
