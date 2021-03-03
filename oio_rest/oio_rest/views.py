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
    settings,
    tilstand,
)
from oio_rest.custom_exceptions import OIOFlaskException
from oio_rest.db import management as db_mgmt
from oio_rest.settings import config

logger = logging.getLogger(__name__)

"""
    Jinja2 Environment
"""

current_directory = os.path.dirname(os.path.realpath(__file__))

jinja_env = Environment(
    loader=FileSystemLoader(os.path.join(current_directory, "templates", "html"))
)


app.include_router(
    klassifikation.KlassifikationsHierarki.setup_api(),
    tags=["Klassifikation"],
    prefix=settings.BASE_URL,
)

app.include_router(
    log.LogHierarki.setup_api(),
    tags=["Log"],
    prefix=settings.BASE_URL,
)

app.include_router(
    sag.SagsHierarki.setup_api(),
    tags=["Sag"],
    prefix=settings.BASE_URL,
)

app.include_router(
    organisation.OrganisationsHierarki.setup_api(),
    tags=["Organisation"],
    prefix=settings.BASE_URL,
)

app.include_router(
    dokument.DokumentHierarki.setup_api(),
    tags=["Dokument"],
    prefix=settings.BASE_URL,
)

app.include_router(
    aktivitet.AktivitetsHierarki.setup_api(),
    tags=["Aktivitet"],
    prefix=settings.BASE_URL,
)

app.include_router(
    indsats.IndsatsHierarki.setup_api(),
    tags=["Indsats"],
    prefix=settings.BASE_URL,
)

app.include_router(
    tilstand.TilstandsHierarki.setup_api(),
    tags=["Tilstand"],
    prefix=settings.BASE_URL,
)


@app.get("/")
def root():
    return RedirectResponse(app.url_path_for("sitemap"))


@app.get("/site-map")
def sitemap():
    """Returns a site map over all valid urls.

    .. :quickref: :http:get:`/site-map`

    """
    links = app.routes
    links = filter(lambda route: "GET" in route.methods, links)
    links = map(attrgetter("path"), links)
    return {"site-map": sorted(links)}


@app.get("/version")
def version():
    version = {"lora_version": __version__}
    return version


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
    db_mgmt.truncate_db(config["database"]["db_name"])
    return PlainTextResponse("Database truncated")


if settings.config["testing_api"]["enable"]:
    app.include_router(testing_router, tags=["Testing"], prefix="/testing")

if settings.config["truncate_api"]["enable"]:
    app.include_router(db_router, tags=["Database Management"], prefix="/db")


@app.exception_handler(OIOFlaskException)
def handle_not_allowed(request: Request, exc: OIOFlaskException):
    dct = exc.to_dict()
    return JSONResponse(status_code=exc.status_code, content=dct)


@app.exception_handler(HTTPException)
def http_exception(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.status_code, "text": str(exc)},
    )


# After request handle for logging.
# Auxiliary functions to get data to be logged.


# def get_service_name():
#    "Get the hierarchy of the present method call from the request URL"
#    u = urllib.parse.urlparse(request.url)
#    urlpath = u.path
#    service_name = urlpath.split("/")[1].capitalize()
#
#    return service_name
#
#
# def get_class_name():
#    "Get the hierarchy of the present method call from the request URL"
#    url = urllib.parse.urlparse(request.url)
#    class_name = url.path.split("/")[2].capitalize()
#    return class_name
#
#
# TODO: Implement this
# @app.after_request
# def log_api_call(response):
#    if hasattr(request, "api_operation"):
#        service_name = get_service_name()
#        class_name = get_class_name()
#        time = datetime.datetime.now()
#        operation = request.api_operation
#        return_code = response.status_code
#        msg = response.status
#        note = "Is there a note too?"
#        user_uuid = get_authenticated_user()
#        object_uuid = getattr(request, "uuid", None)
#        log_service_call(
#            service_name,
#            class_name,
#            time,
#            operation,
#            return_code,
#            msg,
#            note,
#            user_uuid,
#            "N/A",
#            object_uuid,
#        )
#    return response


@app.exception_handler(DataError)
def handle_db_error(request: Request, exc: DataError):
    message = exc.diag.message_primary
    context = exc.diag.context or exc.pgerror.split("\n", 1)[-1]

    return JSONResponse(
        status_code=400, content={"message": message, "context": context}
    )


if __name__ == "__main__":
    app.run(debug=True)
