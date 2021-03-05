# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

import copy
import logging
from logging.handlers import RotatingFileHandler
import pprint
from oio_rest import settings

from flask import Flask

__version__ = "1.10.0"

# we need to add a log handler here, so we see logs from settings.py.
# I mean, we /want/ this handler too.
log_format = logging.Formatter("[%(asctime)s] [%(name)s] [%(levelname)s] %(message)s")

log_level = settings.config["log"]["log_level"]
logger = logging.getLogger()

logger.setLevel(log_level)
logger.setLevel(min(logger.getEffectiveLevel(), logging.INFO))

stdout_log_handler = logging.StreamHandler()
stdout_log_handler.setFormatter(log_format)
stdout_log_handler.setLevel(log_level)
logger.addHandler(stdout_log_handler)

# settings requires the app object to exist so it can locate the
# default-settings.toml file.
app = Flask(__name__)

# The trace log contains debug statements (in context with everything
# higher precedens!) and is intended to be read by humans (tm) when
# something goes wrong. Please *do* write tracebacks and perhaps even
# pprint.pformat these messages.
file_log_handler = RotatingFileHandler(
    filename=settings.config["log"]["log_path"],
    maxBytes=1000000,
)
file_log_handler.setFormatter(log_format)
file_log_handler.setLevel(log_level)
logger.addHandler(file_log_handler)

# The activity log is for everything that isn't debug information. Only
# write single lines and no exception tracebacks here as it is harder to
# parse.
activity_log_handler = RotatingFileHandler(
    filename=settings.config["log"]["activity_log_path"],
    maxBytes=1000000,
)
activity_log_handler.setFormatter(log_format)
activity_log_handler.setLevel(logging.INFO)
logger.addHandler(activity_log_handler)

logger = logging.getLogger(__name__)
safe_config = copy.deepcopy(settings.config)
safe_config["database"]["password"] = "********"
logger.debug("Config:\n%s.", pprint.pformat(safe_config))
logger.info("Config: %s.", safe_config)
del safe_config  # could get out of sync

# now that logging is setup, we can make sure that all routes are added to the
# app object
import oio_rest.views  # noqa
