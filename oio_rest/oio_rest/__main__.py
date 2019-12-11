# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import sys
import time

import click
import flask.cli

from oio_rest import app
from oio_rest.settings import config
from oio_rest.db import db_templating
from oio_rest.db.management import (
    apply_templates,
    check_connection,
    check_templates,
    truncate_db,
)


@click.group(cls=flask.cli.FlaskGroup, create_app=lambda: app)
def cli():
    """Management script for OIO REST."""


@cli.command()
@click.option('-o', '--output', type=click.File('wt'), default='-')
def sql(output):
    '''Write database SQL structure to standard output'''

    for line in db_templating.get_sql():
        output.write(line)
        output.write('\n')


@cli.command()
@click.option("--wait", default=None, type=int,
              help="Wait up to n seconds for the database connection before"
                   " exiting.")
def initdb(wait):
    """Initialize database.

    This is supposed to be idempotent, so you can run it without fear
    on an already initialized database.
    """
    SLEEPING_TIME = 0.25

    attempts = 1 if wait is None else int(wait // SLEEPING_TIME)
    for i in range(1, attempts + 1):
        if check_connection():
            break
        if i == attempts:
            sys.exit(1)
        click.echo("Postgres is unavailable - attempt %s/%s" % (i, attempts))
        time.sleep(SLEEPING_TIME)

    if check_templates():
        click.echo("Database already initialised; nothing happens.")
        return

    click.echo("Initializing database.")
    apply_templates()
    click.echo("Database initialised.")


@cli.command()
def truncatedb():
    """Empty all tables in the database."""
    truncate_db(config["database"]["db_name"])


if __name__ == '__main__':
    cli()
