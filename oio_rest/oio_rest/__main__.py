# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import click
import flask.cli
import psycopg2

from . import app
from . import settings
from .db import db_templating, get_connection


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
def initdb():
    '''Write database SQL structure to standard output'''
    setup_sql = """
    create schema actual_state authorization {db_user};
    alter database {database} set search_path to actual_state, public;
    alter database {database} set datestyle to 'ISO, YMD';
    alter database {database} set intervalstyle to 'sql_standard';
    create extension if not exists "uuid-ossp" with schema actual_state;
    create extension if not exists "btree_gist" with schema actual_state;
    create extension if not exists "pg_trgm" with schema actual_state;
    """.format(db_user=settings.DB_USER, database=settings.DATABASE)
    conn = psycopg2.connect(
        dbname=settings.DATABASE,
        user=settings.DB_USER,
        password=settings.DB_PASSWORD,
        host=settings.DB_HOST,
        port=settings.DB_PORT,
    )
    cursor = conn.cursor()
    cursor.execute(setup_sql)
    conn.commit()

    with get_connection() as conn, conn.cursor() as cursor:
        cursor.execute("\n".join(db_templating.get_sql()))
        conn.commit()



if __name__ == '__main__':
    cli()
