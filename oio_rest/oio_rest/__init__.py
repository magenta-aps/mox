# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


from fastapi import FastAPI
from os2mo_fastapi_utils.tracing import setup_instrumentation, setup_logging
from structlog.contextvars import merge_contextvars
from structlog.processors import JSONRenderer

__version__ = "1.13.1"

app = FastAPI()
app = setup_instrumentation(app)

# now that logging is setup, we can make sure that all routes are added to the
# app object
import oio_rest.views  # noqa

setup_logging(processors=[merge_contextvars, JSONRenderer()])
