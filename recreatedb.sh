#!/bin/bash

## Check if executed as root
if [ $( whoami ) == "root" ]; then
    echo "Do not run as root. We'll sudo when necessary"
exit 1;
fi

# Base dir
BASE_DIR=$( pwd )

# Recreate
INSTALLER_DIR=${BASE_DIR}/installer

# Path to (python) virtual environment
VIRTUALENV=${BASE_DIR}/venv-linux

# Path to python executable
PYTHON_EXEC=${VIRTUALENV}/bin/python

# SUPERUSER
sudo $PYTHON_EXEC ${INSTALLER_DIR}/recreatedb.py