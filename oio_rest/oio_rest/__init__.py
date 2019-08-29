# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import copy
import logging
from logging.handlers import RotatingFileHandler
import pprint

from flask import Flask


# we need to add a log handler here, so we see logs from settings.py.
# I mean, we /want/ this handler too.
log_format = logging.Formatter(
    "[%(asctime)s] [%(name)s] [%(levelname)s] %(message)s"
)
stdout_log_handler = logging.StreamHandler()
stdout_log_handler.setFormatter(log_format)
stdout_log_handler.setLevel(logging.DEBUG)  # this can be higher
logging.getLogger().setLevel(logging.DEBUG)
logging.getLogger().addHandler(stdout_log_handler)

# settings requires the app object to exist so it can locate the
# default-settings.toml file.
app = Flask(__name__)
from oio_rest import settings  # noqa

if app.config["ENV"] == "production":
    # The activity log is for everything that isn't debug information. Only
    # write single lines and no exception tracebacks here as it is harder to
    # parse.
    activity_log_handler = RotatingFileHandler(
        filename=settings.config["log"]["activity_log_path"],
        maxBytes=1000000,
    )
    activity_log_handler.setFormatter(log_format)
    activity_log_handler.setLevel(logging.INFO)
    logging.getLogger().addHandler(activity_log_handler)

    # The trace log contains debug statements (in context with everything
    # higher precedens!) and is intended to be read by humans (tm) when
    # something goes wrong. Please *do* write tracebacks and perhaps even
    # pprint.pformat these messages.
    trace_log_handler = RotatingFileHandler(
        filename=settings.config["log"]["trace_log_path"],
        maxBytes=1000000,
    )
    trace_log_handler.setFormatter(log_format)
    trace_log_handler.setLevel(logging.DEBUG)
    logging.getLogger().addHandler(trace_log_handler)

logger = logging.getLogger(__name__)
safe_config = copy.deepcopy(settings.config)
safe_config["database"]["password"] = "********"
logger.debug("Config:\n%s.", pprint.pformat(safe_config))
logger.info("Config: %s.", safe_config)
del safe_config  # could get out of sync

# now that logging is setup, we can make sure that all routes are added to the
# app object
import oio_rest.views  # noqa
