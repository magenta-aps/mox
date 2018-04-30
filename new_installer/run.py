# -- coding: utf-8 --

import os
import sys
import salt.client
import salt.config


# Settings
base_dir = os.getcwd()

# Installer directory
installer_dir = os.path.dirname(
    os.path.abspath(__file__)
)

# Salt base (Root of salt states)
salt_base = os.path.join(installer_dir, "base")

# Import salt config
__opts__ = salt.config.minion_config("salt.conf")

# Set file roots (relative to rootdir)
__opts__['file_roots'] = {
    "base": [
        salt_base
    ]
}

# Minion caller client
# This used in a masterless configuration
caller = salt.client.Caller(mopts=__opts__)

run_state = caller.cmd("state.apply")
print(run_state)
