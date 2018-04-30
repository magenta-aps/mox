# -- coding: utf-8 --

import os
import sys
import pwd
import grp
from socket import gethostname
from salt import client
from salt import config


# Base dir / root of git repository
base_dir = os.getcwd()

# Installer directory
installer_dir = os.path.dirname(
    os.path.abspath(__file__)
)

# Import salt config
__opts__ = config.minion_config("salt.conf")

# Set file roots (relative to rootdir)
salt_base = os.path.join(installer_dir, "base")

__opts__['file_roots'] = {
    "base": [
        salt_base
    ]
}

# Minion caller client
# This used in a masterless configuration
caller = client.Caller(mopts=__opts__)


# Grains / Configuration variables
hostname = gethostname()
uid = os.getuid()
gid = os.getgid()
user = pwd.getpwuid(uid).pw_name
group = grp.getgrgid(gid).gr_name
virtualenv = "{root}/python-env".format(root=base_dir)
python_exec = "{venv}/bin/python".format(venv=virtualenv)

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
print(set_grains)

# Apply state
run_state = caller.cmd("state.apply")
print(run_state)
