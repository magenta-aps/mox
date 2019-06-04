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
from . import settings
from .db import db_templating


@click.group(cls=flask.cli.FlaskGroup, create_app=lambda: app.app)
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
@click.option("--force/--no-force", default=False, help="Overwrite tables")
@click.option("--wait", default=None, type=int,
              help="Wait n seconds for database.")
def initdb(force, wait):
    """Initialize database."""
    setup_sql = """
    create schema actual_state authorization {db_user};
    alter database {database} set search_path to actual_state, public;
    alter database {database} set datestyle to 'ISO, YMD';
    alter database {database} set intervalstyle to 'sql_standard';
    create extension if not exists "uuid-ossp" with schema actual_state;
    create extension if not exists "btree_gist" with schema actual_state;
    create extension if not exists "pg_trgm" with schema actual_state;
    """.format(
        db_user=settings.DB_USER, database=settings.DATABASE
    )
    init_check_sql = (
        "select nspname"
        "  from pg_catalog.pg_namespace"
        " where nspname = 'actual_state';"
    )
    drop_schema_sql = "drop schema actual_state cascade;"
    sleeping_time = 0.25

    def _new_db_connection():
        # We need two different connections. For some reason, a connection
        # cannot use the extenstions it just created. This is also why we
        # cannot use db.get_connection, as it may return the same connection
        # (it uses a pool).  I do not know whether this is because of postgres
        # 9.6 or psycopg2.
        return psycopg2.connect(
            dbname=settings.DATABASE,
            user=settings.DB_USER,
            password=settings.DB_PASSWORD,
            host=settings.DB_HOST,
            port=settings.DB_PORT,
        )

    attempts = 1 if wait is None else int(wait // sleeping_time)
    for i in range(1, attempts + 1):
        try:
            conn = _new_db_connection()
            break
        except psycopg2.OperationalError:
            click.echo(
                "Postgres is unavailable - attempt %s/%s" % (i, attempts))
            if i == attempts:
                sys.exit(1)
            time.sleep(sleeping_time)

    cursor = conn.cursor()
    cursor.execute(init_check_sql)
    initialised = bool(cursor.fetchone())

    if initialised:
        if force:
            click.echo("Database already initialised; clearing.")
            cursor.execute(drop_schema_sql)
            conn.commit()
        else:
            click.echo(
                "Database already initialised; nothing happens. "
                "Use --force to reinitialise."
            )
            return

    cursor.execute(setup_sql)
    conn.commit()
    conn.close()

    conn = _new_db_connection()
    cursor = conn.cursor()
    cursor.execute("\n".join(db_templating.get_sql()))
    conn.commit()
    conn.close()

    click.echo("Database initialised.")


if __name__ == '__main__':
    cli()
