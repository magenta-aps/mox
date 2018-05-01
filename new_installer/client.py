# -- coding: utf-8 --

from salt import client
from salt import config

# Installer directory
installer_dir = os.path.dirname(
    os.path.abspath(__file__)
)

# Path to config
salt_config = os.path.join(installer_dir, "salt.conf")

# Import salt config
__opts__ = config.minion_config(salt_config)

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
