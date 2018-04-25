# -- coding: utf-8 --
import os
import salt.client
import salt.config

__opts__ = salt.config.minion_config("salt.conf")

# Set root dir:
__opts__["root_dir"] = "/opt/magenta"

# Set file roots (relative to rootdir)
__opts__['file_roots'] = {
    "base": [
       "/opt/magenta/local"
     ]
}

# Minion caller client
# This used in a masterless configuration
caller = salt.client.Caller(mopts=__opts__)

# Run command on self
testing = caller.cmd("cmd.run", ["whoami"])
print(testing)

run_state = caller.cmd("state.apply", "common.deps")
print(run_state)
