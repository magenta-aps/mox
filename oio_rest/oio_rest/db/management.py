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
import psycopg2.pool
from psycopg2.sql import SQL, Identifier

from oio_rest.db import close_pool, db_templating
from oio_rest.settings import config

logger = logging.getLogger(__name__)

dbname = Identifier(config["database"]["db_name"])
dbname_backup = Identifier(config["database"]["db_name"] + "_backup")
dbname_template = Identifier(config["database"]["db_name"] + "_template")


def apply_templates():
    """Initialize the database with templates."""
    with _get_connection() as conn, conn.cursor() as curs:
        curs.execute("\n".join(db_templating.get_sql()))


def check_templates():
    """Check whether the database is initialized."""

    # check that 'bruger' table exists. This is arbitrary.
    INIT_CHECK_SQL = SQL(
        "select relname from pg_catalog.pg_class where relname = 'bruger';"
    )

    with _get_connection() as conn, conn.cursor() as curs:
        curs.execute(INIT_CHECK_SQL)
        return bool(curs.fetchone())


def check_connection():
    try:
        _get_connection()
        return True
    except psycopg2.OperationalError:
        return False


def testdb_create_template_db():
    """Create a copy of the database to be used as a template in the future. This
    should only be used right after initdb() have been run and no other data
    have been added.

    Requires CREATEDB or SUPERUSER privileges.

    """
    _cpdb(dbname, dbname_template)


def testdb_setup():
    """Move the database specified in settings to a backup location and reset the
    database specified in the settings. This makes the database ready for
    testing while still preserving potential data written to the database. Use
    `testdb_teardown()` to reverse this.

    Requires CREATEDB and OWNER or SUPERUSER privileges.

    """
    logger.info("Setting up test database")
    _dropdb(dbname_backup)
    _cpdb(dbname, dbname_backup)

    testdb_reset()


def testdb_reset():
    """Reset the database specified in settings from the template. Requires the
    template database to be created.

    Requires CREATEDB and OWNER or SUPERUSER privileges.

    """


    # TODO Check if the template db is created before dropping.
    logger.info("Resetting test database")
    _dropdb(dbname)
    _cpdb(dbname_template, dbname)


def testdb_teardown():
    """Move the database at the backup location back to database location specified
    in the settings. Remove the changes made by `testdb_setup()`.

    Requires CREATEDB and OWNER or SUPERUSER privileges.

    """
    logger.info("Removing test database")
    _dropdb(dbname)
    _cpdb(dbname_backup, dbname)
    _dropdb(dbname_backup)


def _get_connection(dbname=None):
    """Return a simple connection to the pg database instance with the credentials
    from settings. Allows database name to be overwritten.

    If you use the database named `template1`, you can DROP DATABASE named
    `config["database"]["db_name"]`. The default template database `template1`
    should always be present.

    """
    if dbname is None:
        dbname = config["database"]["db_name"]

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
    close_pool()
    logger.debug(
        "Copying database from %s to %s", dbname_from.string, dbname_to.string
    )
    with _get_connection(dbname="template1") as conn:
        conn.set_isolation_level(
            psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT
        )
        with conn.cursor() as curs:
            curs.execute(
                SQL("create database {} with template {};").format(
                    dbname_to, dbname_from
                )
            )

            # The three following `alter database … set` commands should be
            # identical the ones in docker/postgresql-initdb.d/10-init-db.sh
            # used in production.
            curs.execute(
                SQL(
                    "ALTER DATABASE {} SET search_path TO "
                    "actual_state, public;"
                ).format(dbname_to)
            )
            curs.execute(
                SQL("ALTER DATABASE {} SET datestyle TO 'ISO, YMD';").format(
                    dbname_to
                )
            )
            curs.execute(
                SQL(
                    "ALTER DATABASE {} SET intervalstyle TO 'sql_standard';"
                ).format(dbname_to)
            )

            # The tests are written as if the computer has the local time zone
            # set to 'Europe/Copenhagen'. This setting makes postgresql spit
            # out dates in the format the tests expect. This is not part of the
            # database sql or templates because we don't want a hardcoded
            # timezone in production.
            curs.execute(
                SQL(
                    "ALTER DATABASE {} SET time zone 'Europe/Copenhagen';"
                ).format(dbname_to)
            )


def _dropdb(dbname):
    """Deletes a pg database object.

    Requires OWNER or SUPERUSER privileges.
    """
    close_pool()
    logger.debug("Dropping database %s", dbname.string)
    with _get_connection(dbname="template1") as conn:
        conn.set_isolation_level(
            psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT
        )
        with conn.cursor() as curs:
            curs.execute(SQL("DROP DATABASE IF EXISTS {};").format(dbname))
