#
# Copyright (c) 2017-2019, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#


# The functions in this file are for initialising, resetting and checking
# databases for both the normal operation and for testing.


import logging

import psycopg2
import psycopg2.extensions
from psycopg2.sql import SQL, Identifier

from oio_rest.db import close_connection, db_templating
from oio_rest.settings import config

logger = logging.getLogger(__name__)

DBNAME = config["database"]["db_name"]
DBNAME_BACKUP = config["database"]["db_name"] + "_backup"
DBNAME_INITIALIZED_TEMPLATE = config["database"]["db_name"] + "_template"
# The postgres default (empty) template for CREATE DATABASE.
DBNAME_SYS_TEMPLATE = "template1"


def apply_templates(dbname=None):
    """Initialize the database with templates."""
    with _get_connection(dbname) as conn, conn.cursor() as curs:
        curs.execute("\n".join(db_templating.get_sql()))


def check_templates(dbname=None):
    """Check whether the database is initialized."""

    # check that 'bruger' table exists. This is arbitrary.
    INIT_CHECK_SQL = SQL(
        "select relname from pg_catalog.pg_class where relname = 'bruger';"
    )

    with _get_connection(dbname) as conn, conn.cursor() as curs:
        curs.execute(INIT_CHECK_SQL)
        return bool(curs.fetchone())


def check_connection():
    try:
        _get_connection(DBNAME)
        return True
    except psycopg2.OperationalError:
        return False


def testdb_setup(from_scratch=False):
    """Move the database specified in settings to a backup location and reset the
    database specified in the settings. This makes the database ready for
    testing while still preserving potential data written to the database. Use
    `testdb_teardown()` to reverse this.

    Requires CREATEDB and OWNER or SUPERUSER privileges.

    """
    logger.info("Setting up test database")
    _dropdb(DBNAME_BACKUP)
    _cpdb(DBNAME, DBNAME_BACKUP)

    testdb_reset(from_scratch)


def testdb_reset(from_scratch=False):
    """Reset the database specified in settings from the template. Requires the
    template database to be created.

    Requires CREATEDB and OWNER or SUPERUSER privileges.

    """

    logger.info("Resetting test database")
    _dropdb(DBNAME)
    if from_scratch:
        _createdb(DBNAME)
    else:
        def _check_database():
            with _get_connection(DBNAME_SYS_TEMPLATE) as conn, conn.cursor() as curs:
                    curs.execute(
                        "select datname from pg_catalog.pg_database where datname=%s",
                        [DBNAME_INITIALIZED_TEMPLATE],
                    )
                    return bool(curs.fetchone())

        if not _check_database():
            _createdb(DBNAME_INITIALIZED_TEMPLATE)

        _cpdb(DBNAME_INITIALIZED_TEMPLATE, DBNAME)


def testdb_teardown():
    """Move the database at the backup location back to database location specified
    in the settings. Remove the changes made by `testdb_setup()`.

    Requires CREATEDB and OWNER or SUPERUSER privileges.

    """
    logger.info("Removing test database")
    _dropdb(DBNAME)
    _cpdb(DBNAME_BACKUP, DBNAME)
    _dropdb(DBNAME_BACKUP)


def _get_connection(dbname):
    """Return a simple connection to the pg database instance with the credentials
    from settings. Allows database name to be overwritten.

    If you use the database named `template1`, you can DROP DATABASE named
    `config["database"]["db_name"]`. The default template database `template1`
    should always be present.

    """
    return psycopg2.connect(
        dbname=dbname,
        user=config["database"]["user"],
        password=config["database"]["password"],
        host=config["database"]["host"],
        port=config["database"]["port"],
    )


def _cpdb(dbname_from, dbname_to):
    """Copy a pg database object and add the attributes oio_rest expects.

    This creates a new database and uses `dbname_from` as a template for that database.
    It copys all structures and data. The database attribrutes (set with `ALTER
    DATABASE`) are not copyed, so they are set afterwards.

    Requires CREATEDB or SUPERUSER privileges.

    """
    close_connection()
    logger.debug("Copying database from %s to %s", dbname_from, dbname_to)
    with _get_connection(DBNAME_SYS_TEMPLATE) as conn:
        conn.set_isolation_level(
            psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT
        )
        with conn.cursor() as curs:
            curs.execute(
                SQL("create database {} with template {};").format(
                    Identifier(dbname_to), Identifier(dbname_from)
                )
            )

            # The three following `alter database … set` commands should be
            # identical the ones in docker/postgresql-initdb.d/10-init-db.sh
            # used in production.
            curs.execute(
                SQL(
                    "ALTER DATABASE {} SET search_path TO "
                    "actual_state, public;"
                ).format(Identifier(dbname_to))
            )
            curs.execute(
                SQL("ALTER DATABASE {} SET datestyle TO 'ISO, YMD';").format(
                    Identifier(dbname_to)
                )
            )
            curs.execute(
                SQL(
                    "ALTER DATABASE {} SET intervalstyle TO 'sql_standard';"
                ).format(Identifier(dbname_to))
            )

            # The tests are written as if the computer has the local time zone
            # set to 'Europe/Copenhagen'. This setting makes postgresql spit
            # out dates in the format the tests expect. This is not part of the
            # database sql or templates because we don't want a hardcoded
            # timezone in production.
            curs.execute(
                SQL(
                    "ALTER DATABASE {} SET time zone 'Europe/Copenhagen';"
                ).format(Identifier(dbname_to))
            )


def _dropdb(dbname):
    """Deletes a pg database object.

    Requires OWNER or SUPERUSER privileges.
    """
    close_connection()
    logger.debug("Dropping database %s", dbname)
    with _get_connection(DBNAME_SYS_TEMPLATE) as conn:
        conn.set_isolation_level(
            psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT
        )
        with conn.cursor() as curs:
            curs.execute(
                SQL("DROP DATABASE IF EXISTS {};").format(Identifier(dbname))
            )


def _createdb(dbname):
    """Create a new database and initialize it with objects from templates. Drops a
    potential database with the same name first.

    Requires CREATEDB or SUPERUSER privileges.

    """
    _dropdb(dbname)
    _cpdb(DBNAME_SYS_TEMPLATE, dbname)

    with _get_connection(dbname) as conn, conn.cursor() as curs:
        # The following `create schema …` command should be identical the one
        # in docker/postgresql-initdb.d/10-init-db.sh used in production.
        curs.execute(
            SQL("create schema actual_state authorization {};").format(
                Identifier(config["database"]["user"])
            )
        )
        # The three following `create extension … ` commands should be
        # identical the ones in
        # docker/postgresql-initdb.d/20-create-extensions.sh used in
        # production.
        for ext in ["uuid-ossp", "btree_gist", "pg_trgm"]:
            curs.execute(
                SQL(
                    "create extension if not exists {} with schema "
                    "actual_state;"
                ).format(Identifier(ext))
            )

    apply_templates(dbname)
