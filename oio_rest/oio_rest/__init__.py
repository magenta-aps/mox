# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

import copy

from oio_rest import settings
from os2mo_fastapi_utils.tracing import setup_instrumentation, setup_logging
from structlog import get_logger
from structlog.processors import JSONRenderer
from structlog.contextvars import merge_contextvars

from fastapi import FastAPI

__version__ = "1.13.0"

app = FastAPI()
app = setup_instrumentation(app)

logger = get_logger()
safe_config = copy.deepcopy(settings.config)
safe_config["database"]["password"] = "********"
logger.debug("Config: %s", config=safe_config)
logger.info("Config: %s", config=safe_config)
del safe_config  # could get out of sync

# now that logging is setup, we can make sure that all routes are added to the
# app object
import oio_rest.views  # noqa

setup_logging(processors=[merge_contextvars, JSONRenderer()])
