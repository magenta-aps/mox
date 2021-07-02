# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

import logging

from os2mo_fastapi_utils.tracing import setup_instrumentation

from fastapi import FastAPI

__version__ = "1.13.0"

from oio_rest import config

log_format = logging.Formatter("[%(asctime)s] [%(name)s] [%(levelname)s] %(message)s")

log_level = config.get_settings().lora_log_level
logger = logging.getLogger()

logger.setLevel(log_level)
logger.setLevel(min(logger.getEffectiveLevel(), logging.INFO))

stdout_log_handler = logging.StreamHandler()
stdout_log_handler.setFormatter(log_format)
stdout_log_handler.setLevel(log_level)
logger.addHandler(stdout_log_handler)

# settings requires the app object to exist so it can locate the
# default-settings.toml file.
app = FastAPI()
app = setup_instrumentation(app)

# now that logging is setup, we can make sure that all routes are added to the
# app object
import oio_rest.views  # noqa
