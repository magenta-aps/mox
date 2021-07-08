# SPDX-FileCopyrightText: 2015-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0

import logging
import os
from operator import attrgetter

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import JSONResponse, RedirectResponse, PlainTextResponse
from jinja2 import Environment, FileSystemLoader
from psycopg2 import DataError

from oio_rest import (
    __version__,
    aktivitet,
    app,
    dokument,
    indsats,
    klassifikation,
    log,
    organisation,
    sag,
    tilstand,
    config,
)
from oio_rest.custom_exceptions import OIOException
from oio_rest.db import management as db_mgmt

logger = logging.getLogger(__name__)

"""
    Jinja2 Environment
"""

current_directory = os.path.dirname(os.path.realpath(__file__))

jinja_env = Environment(
    loader=FileSystemLoader(os.path.join(current_directory, "templates", "html"))
)


@app.get("/", tags=["Meta"])
def root():
    return RedirectResponse(app.url_path_for("sitemap"))


@app.get("/site-map", tags=["Meta"])
def sitemap():
    """Returns a site map over all valid urls.

    .. :quickref: :http:get:`/site-map`

    """
    links = app.routes
    links = filter(lambda route: "GET" in route.methods, links)
    links = map(attrgetter("path"), links)
    return {"site-map": sorted(links)}


@app.get("/version", tags=["Meta"])
def version():
    version = {"lora_version": __version__}
    return version


app.include_router(
    klassifikation.KlassifikationsHierarki.setup_api(),
    tags=["Klassifikation"],
)

app.include_router(
    log.LogHierarki.setup_api(),
    tags=["Log"],
)

app.include_router(
    sag.SagsHierarki.setup_api(),
    tags=["Sag"],
)

app.include_router(
    organisation.OrganisationsHierarki.setup_api(),
    tags=["Organisation"],
)

app.include_router(
    dokument.DokumentHierarki.setup_api(),
    tags=["Dokument"],
)

app.include_router(
    aktivitet.AktivitetsHierarki.setup_api(),
    tags=["Aktivitet"],
)

app.include_router(
    indsats.IndsatsHierarki.setup_api(),
    tags=["Indsats"],
)

app.include_router(
    tilstand.TilstandsHierarki.setup_api(),
    tags=["Tilstand"],
)


testing_router = APIRouter()


@testing_router.get("/db-setup")
def testing_db_setup():
    logger.debug("Test database setup endpoint called")
    db_mgmt.testdb_setup()
    return PlainTextResponse("Test database setup")


@testing_router.get("/db-reset")
def testing_db_reset():
    logger.debug("Test database reset endpoint called")
    db_mgmt.testdb_reset()
    return PlainTextResponse("Test database reset")


@testing_router.get("/db-teardown")
def testing_db_teardown():
    logger.debug("Test database teardown endpoint called")
    db_mgmt.testdb_teardown()
    return PlainTextResponse("Test database teardown")


db_router = APIRouter()


@db_router.get("/truncate")
def truncate_db():
    logger.debug("Truncate DB endpoint called")
    db_mgmt.truncate_db(config.get_settings().db_name)
    return PlainTextResponse("Database truncated")


if config.get_settings().testing_api:
    app.include_router(testing_router, tags=["Testing"], prefix="/testing")

if config.get_settings().truncate_api:
    app.include_router(db_router, tags=["Database Management"], prefix="/db")


@app.exception_handler(OIOException)
def handle_not_allowed(request: Request, exc: OIOException):
    dct = exc.to_dict()
    return JSONResponse(status_code=exc.status_code, content=dct)


@app.exception_handler(HTTPException)
def http_exception(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.status_code, "text": str(exc.detail)},
    )


@app.exception_handler(DataError)
def handle_db_error(request: Request, exc: DataError):
    message = exc.diag.message_primary
    context = exc.diag.context or exc.pgerror.split("\n", 1)[-1]

    return JSONResponse(
        status_code=400, content={"message": message, "context": context}
    )


if __name__ == "__main__":
    app.run(debug=True)
