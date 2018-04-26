# -- coding: utf-8 --

import os
import sys
import salt.client
import salt.config


# Env variables
base_dir = os.environ.get("BASE_DIR", None)
installer_dir = os.environ.get("INSTALLER_DIR", None)


if not base_dir or not installer_dir:
    sys.exit(
        "Installer variables have not been set"
    )

# Import salt config
__opts__ = salt.config.minion_config("salt.conf")

# Set file roots (relative to rootdir)
__opts__['file_roots'] = {
    "base": [installer_dir]
}

# Minion caller client
# This used in a masterless configuration
caller = salt.client.Caller(mopts=__opts__)

# Run command on self
testing = caller.cmd("cmd.run", ["whoami"])
print(testing)

run_state = caller.cmd("state.apply", "tasks.test")
print(run_state)
