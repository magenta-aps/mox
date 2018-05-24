#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

import atexit
import os
import subprocess
import sys
import tempfile

import click
import mock
import testing.postgresql
import psycopg2.pool
import pytest

from .. import app

import settings

BASE_DIR = os.path.dirname(settings.__file__)
TOP_DIR = os.path.dirname(BASE_DIR)


def _initdb(psql):
    dsn = psql.dsn()

    env = os.environ.copy()

    env.update(
        TESTING='1',
        PYTHON=sys.executable,
        MOX_DB=settings.DATABASE,
        MOX_DB_USER=settings.DB_USER,
        MOX_DB_PASSWORD=settings.DB_PASSWORD,
    )

    with psycopg2.connect(**dsn) as conn:
        conn.autocommit = True

        with conn.cursor() as curs:
            curs.execute(
                "CREATE USER {} WITH SUPERUSER PASSWORD %s".format(
                    settings.DB_USER,
                ),
                (
                    settings.DB_PASSWORD,
                ),
            )

            curs.execute(
                "CREATE DATABASE {} WITH OWNER = %s".format(settings.DATABASE),
                (
                    settings.DB_USER,
                ),
            )

    dsn = dsn.copy()
    dsn['database'] = settings.DATABASE
    dsn['user'] = settings.DB_USER
    dsn['password'] = settings.DB_PASSWORD

    mkdb_path = os.path.join(BASE_DIR, '..', 'db', 'mkdb.sh')

    with psycopg2.connect(**dsn) as conn, conn.cursor() as curs:
        curs.execute(subprocess.check_output([mkdb_path], env=env))


psql_factory = testing.postgresql.PostgresqlFactory(
    cache_initialized_db=True,
    on_initialized=_initdb
)
atexit.register(psql_factory.clear_cache)


@pytest.mark.slow
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

    def setUp(self):
        super(TestCaseMixin, self).setUp()

        psql = psql_factory()
        psql.wait_booting()

        dsn = psql.dsn()

        patches = [
            mock.patch('settings.LOG_AMQP_SERVER', None),
            mock.patch('settings.DB_HOST', dsn['host'],
                       create=True),
            mock.patch('settings.DB_PORT', dsn['port'],
                       create=True),
            mock.patch(
                'oio_rest.db.pool',
                psycopg2.pool.SimpleConnectionPool(
                    1, 1,
                    database=settings.DATABASE,
                    user=settings.DB_USER,
                    password=settings.DB_PASSWORD,
                    host=dsn['host'],
                    port=dsn['port'],
                ),
            ),
        ]

        for p in patches:
            p.start()
            self.addCleanup(p.stop)

        self.addCleanup(psql.stop)



@click.command()
@click.option('-p', '--port', type=int, default=5000)
def run_with_db(**kwargs):
    with testing.postgresql.Postgresql(
        base_dir=tempfile.mkdtemp(prefix='mox'),
        postgres_args=(
            '-h localhost -F '
            '-c logging_collector=off '
            '-c synchronous_commit=off '
            '-c fsync=off'
        ),
    ) as psql:
        # We take over the process, given that this is a CLI command.
        # Hence, there's no need to restore these variables afterwards
        settings.LOG_AMQP_SERVER = None
        settings.DB_HOST = psql.dsn()['host']
        settings.DB_PORT = psql.dsn()['port']

        _initdb(psql)

        app.app.run(**kwargs)


if __name__ == '__main__':
    run_with_db()
