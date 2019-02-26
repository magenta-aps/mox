#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

import atexit
import contextlib
import copy
import functools
import glob
import os
import shutil
import subprocess
import sys
import types
import typing

import click
import mock
import testing.postgresql
import psycopg2.pool

from .. import app
from ..db import db_templating

from .. import settings

BASE_DIR = os.path.dirname(os.path.dirname(settings.__file__))
TOP_DIR = os.path.dirname(BASE_DIR)
DB_DIR = os.path.join(BASE_DIR, 'build', 'db', str(os.getpid()))


@contextlib.contextmanager
def patch_db_struct(new: typing.Union[types.ModuleType, dict]):
    '''Context manager for overriding db_structures'''

    patches = [
        mock.patch('oio_rest.db.db_helpers._attribute_fields', {}),
        mock.patch('oio_rest.db.db_helpers._attribute_names', {}),
        mock.patch('oio_rest.db.db_helpers._relation_names', {}),
        mock.patch('oio_rest.validate.SCHEMAS', {}),
        mock.patch('oio_rest.settings.REAL_DB_STRUCTURE', new=new),
    ]

    if isinstance(new, types.ModuleType):
        patches += [
            mock.patch('oio_rest.settings.REAL_DB_STRUCTURE',
                       new=new.REAL_DB_STRUCTURE),
            mock.patch('oio_rest.settings.DB_STRUCTURE.REAL_DB_STRUCTURE',
                       new=new.REAL_DB_STRUCTURE),
        ]

    with contextlib.ExitStack() as stack:
        for patch in patches:
            stack.enter_context(patch)

        yield


@contextlib.contextmanager
def extend_db_struct(new: dict):
    '''Context manager for extending db_structures'''

    dbs = copy.deepcopy(settings.DB_STRUCTURE.DATABASE_STRUCTURE)
    real_dbs = copy.deepcopy(settings.REAL_DB_STRUCTURE)

    patches = [
        mock.patch('oio_rest.db.db_helpers._attribute_fields', {}),
        mock.patch('oio_rest.db.db_helpers._attribute_names', {}),
        mock.patch('oio_rest.db.db_helpers._relation_names', {}),
        mock.patch('oio_rest.validate.SCHEMAS', {}),
        mock.patch('oio_rest.settings.DB_STRUCTURE.DATABASE_STRUCTURE',
                   new=dbs),
        mock.patch('oio_rest.settings.REAL_DB_STRUCTURE', new=real_dbs),
        mock.patch('oio_rest.settings.DB_STRUCTURE.REAL_DB_STRUCTURE',
                   new=real_dbs),
    ]

    with contextlib.ExitStack() as stack:
        for patch in patches:
            stack.enter_context(patch)

        settings.load_db_extensions(new)

        yield


@functools.lru_cache()
def psql():
    os.makedirs(DB_DIR, exist_ok=True)

    psql = testing.postgresql.Postgresql(
        base_dir=DB_DIR,
        postgres_args=(
            '-h 127.0.0.1 -F -c logging_collector=off '
            '-c fsync=off -c unix_socket_directories=/tmp'
        ),
    )

    atexit.register(psql.stop)
    atexit.register(lambda: shutil.rmtree(DB_DIR))

    return psql


def _initdb():
    with psycopg2.connect(
        psql().url(),
        database="postgres",
        user="postgres",
    ) as conn:
        conn.autocommit = True

        with conn.cursor() as curs:
            curs.execute('CREATE USER {} WITH PASSWORD {!r}'.format(
                settings.DB_USER, settings.DB_PASSWORD,
            ))

            curs.execute('CREATE DATABASE {} WITH OWNER = {!r}'.format(
                settings.DATABASE, settings.DB_PASSWORD,
            ))

            # The tests are written as if the computer has the local
            # time zone set to 'Europe/Copenhagen'. This setting
            # makes postgresql spit out dates in the format the tests
            # expect. This is not part of the database sql or templates
            # because we don't want a hardcoded timezone in production.
            curs.execute("ALTER DATABASE {} SET time zone 'Europe/Copenhagen'".format(settings.DATABASE))

    with psycopg2.connect(
        psql().url(),
        database=settings.DATABASE,
        user="postgres",
    ) as conn:
        conn.autocommit = True

        with conn.cursor() as curs:
            curs.execute("CREATE SCHEMA actual_state AUTHORIZATION {}".format(settings.DB_USER))
            curs.execute("ALTER DATABASE {} SET search_path TO actual_state, public".format(settings.DATABASE))
            curs.execute("ALTER DATABASE {} SET DATESTYLE to 'ISO, YMD'".format(settings.DATABASE))
            curs.execute("ALTER DATABASE {} SET INTERVALSTYLE to 'sql_standard'".format(settings.DATABASE))
            curs.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA actual_state')
            curs.execute('CREATE EXTENSION IF NOT EXISTS "btree_gist" WITH SCHEMA actual_state')
            curs.execute('CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA actual_state')

    with psycopg2.connect(
        psql().url(),
        database=settings.DATABASE,
        user=settings.DB_USER,
        password=settings.DB_PASSWORD,
    ) as conn:
        conn.autocommit = True

        with conn.cursor() as curs:
            for chunk in db_templating.get_sql():
                curs.execute(chunk)


class TestCaseMixin(object):

    '''Base class for LoRA test cases with database access.
    '''

    maxDiff = None

    def get_lora_app(self):
        app.app.config['DEBUG'] = False
        app.app.config['TESTING'] = True
        app.app.config['LIVESERVER_PORT'] = 0
        app.app.config['PRESERVE_CONTEXT_ON_EXCEPTION'] = False

        return app.app

    @contextlib.contextmanager
    def db_cursor(self):
        '''Context manager for querying the database

        :see: `psycopg2.cursor <http://initd.org/psycopg/docs/cursor.html>`_
        '''
        with psycopg2.connect(self.db_url) as conn:
            conn.autocommit = True

            with conn.cursor() as curs:
                yield curs

    def reset_db(self):
        with self.db_cursor() as curs:
            curs.execute("TRUNCATE TABLE {} RESTART IDENTITY CASCADE".format(
                ', '.join(sorted(settings.DB_STRUCTURE.DATABASE_STRUCTURE)),
            ))

    # for compatibility :-/
    __reset_db = reset_db

    def setUp(self):
        super(TestCaseMixin, self).setUp()

        self.db_url = psql().url(
            database=settings.DATABASE,
            user=settings.DB_USER,
            password=settings.DB_PASSWORD,
        )

        try:
            with psycopg2.connect(self.db_url):
                pass
        except psycopg2.DatabaseError:
            _initdb()

        self.addCleanup(self.__reset_db)

        db_host = psql().dsn()['host']
        db_port = psql().dsn()['port']

        stack = contextlib.ExitStack()
        self.addCleanup(stack.close)

        for p in [
            mock.patch('oio_rest.settings.FILE_UPLOAD_FOLDER', './mox-upload'),
            mock.patch('oio_rest.settings.LOG_AMQP_SERVER', None),
            mock.patch('oio_rest.settings.DB_HOST', db_host,
                       create=True),
            mock.patch('oio_rest.settings.DB_PORT', db_port,
                       create=True),
        ]:
            stack.enter_context(p)

    def tearDown(self):
        pool = getattr(self.app, 'pool', None)

        if pool:
            pool.closeall()

            del self.app.pool

        super().tearDown()

    @classmethod
    def tearDownClass(cls):
        with psycopg2.connect(psql().url()) as conn:
            conn.autocommit = True

            with conn.cursor() as curs:
                curs.execute(
                    'DROP DATABASE IF EXISTS {}'.format(settings.DATABASE),
                )
                curs.execute(
                    'DROP USER IF EXISTS {}'.format(settings.DB_USER),
                )


@click.command()
@click.option('--host', '-h', default='::1',
              help='The interface to bind to.')
@click.option('--port', '-p', default=5000,
              help='The port to bind to.')
@click.option('use_reloader', '--reload/--no-reload', default=None,
              help='Enable or disable the reloader.  By default the reloader '
              'is active if debug is enabled.')
@click.option('use_debugger', '--debugger/--no-debugger', default=None,
              help='Enable or disable the debugger.  By default the debugger '
              'is active if debug is enabled.')
@click.option('use_reloader', '--eager-loading/--lazy-loader', default=None,
              help='Enable or disable eager loading.  By default eager '
              'loading is enabled if the reloader is disabled.')
@click.option('threaded', '--with-threads/--without-threads', default=True,
              help='Enable or disable multithreading.')
def run_with_db(**kwargs):
    from oio_rest import db

    with psql():
        dsn = psql().dsn()

        # We take over the process, given that this is a CLI command.
        # Hence, there's no need to restore these variables afterwards
        settings.LOG_AMQP_SERVER = None
        settings.DB_HOST = dsn['host']
        settings.DB_PORT = dsn['port']

        db.pool = psycopg2.pool.PersistentConnectionPool(
            1, 100,
            database=dsn['database'],
            user=dsn['user'],
            password=dsn.get('password'),
            host=dsn['host'],
            port=dsn['port'],
        )

        app.app.run(**kwargs)


if __name__ == '__main__':
    run_with_db()
