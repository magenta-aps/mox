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
import psycopg2

from . import app
from .db import db_templating, get_connection


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
    INIT_CHECK_SQL = (  # check that 'bruger' table exists. This is arbitrary.
        "select relname"
        "  from pg_catalog.pg_class"
        " where relname = 'bruger';"
    )
    SLEEPING_TIME = 0.25

    attempts = 1 if wait is None else int(wait // SLEEPING_TIME)
    for i in range(1, attempts + 1):
        try:
            conn = get_connection()
            break
        except psycopg2.OperationalError:
            click.echo(
                "Postgres is unavailable - attempt %s/%s" % (i, attempts))
            if i == attempts:
                sys.exit(1)
            time.sleep(SLEEPING_TIME)

    cursor = conn.cursor()
    cursor.execute(INIT_CHECK_SQL)
    initialised = bool(cursor.fetchone())

    if initialised:
        click.echo("Database already initialised; nothing happens.")
        return

    click.echo("Initializing database.")
    cursor.execute("\n".join(db_templating.get_sql()))
    conn.commit()
    conn.close()
    click.echo("Database initialised.")


if __name__ == '__main__':
    cli()
