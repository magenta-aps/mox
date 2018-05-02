#!/bin/bash

## Check if executed as root
if [ $( whoami ) == "root" ]; then
    echo "Do not run as root. We'll sudo when necessary"
exit 1;
fi

## Variables

# Base directory (current)
BASE_DIR=$( pwd )

# Setup directory
# TODO: Temporary installer directory name
INSTALLER_DIR=${BASE_DIR}/new_installer

# Setup executable
CONFIGURE=${INSTALLER_DIR}/configure.py
INSTALLER=${INSTALLER_DIR}/install_application.py

# Setup requirements
REQUIREMENTS=${INSTALLER_DIR}/install_requirements.txt

# Path to (python) virtual environment
VIRTUALENV=${BASE_DIR}/venv-linux

# Path to python executable
PYTHON_EXEC=${VIRTUALENV}/bin/python

## Install system dependencies
sudo apt-get install python3 python3-venv python3-dev gcc

## Create virtual environment
/usr/bin/env python3 -m venv ${VIRTUALENV}

## Install python (installer) dependencies
$PYTHON_EXEC -m pip install -r $REQUIREMENTS

# Collect info and set information (grains)
$PYTHON_EXEC $CONFIGURE

## Run installer (as SUPERUSER)
sudo $PYTHON_EXEC $INSTALLER
