# -- coding: utf-8 --

import os
import pwd
import grp
import json
from os import getenv
from socket import gethostname
from client import caller


## Gather and map information
#TODO: Run state to check and verify system current state

# Base dir / root of git repository
base_dir = os.getcwd()

# Hostname
hostname = gethostname()

# User details
uid = os.getuid()
gid = os.getgid()
user = pwd.getpwuid(uid).pw_name
group = grp.getgrgid(gid).gr_name

# Virtual environment and python executable
virtualenv = getenv("VIRTUALENV")
python_exec = getenv("PYTHON_EXEC")

# Create config
db_config = {
    "host": "localhost",
    "name": "mox",
    "user": "mox",
    "pass": "mox",
    "superuser": "postgres"
}

amqp_config = {
    "host": "localhost",
    "port": 5672,
    "user": "guest",
    "pass": "guest",
    "vhost": "/"
}

mox_config = {
    "hostname": hostname,
    "user": user,
    "group": group,
    "base_dir": base_dir,
    "virtualenv": virtualenv,
    "python_exec": python_exec,
    "db": db_config,
    "amqp": amqp_config
}

# Set grains (configuration)
# grains.setval key value
set_grains = caller.cmd("grains.setval", "mox_config", mox_config)

formatted = json.dumps(set_grains, indent=2)

print("""
Set grain/system values for the installation process

{grains}
""".format(grains=formatted))
