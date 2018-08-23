#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

import atexit
import functools
import os
import shutil
import subprocess
import sys

import click
import mock
import testing.postgresql
import psycopg2.pool

from .. import app

import settings

BASE_DIR = os.path.dirname(settings.__file__)
TOP_DIR = os.path.dirname(BASE_DIR)
DB_DIR = os.path.join(BASE_DIR, 'build', 'db')


@functools.lru_cache()
def psql():
    os.makedirs(DB_DIR, exist_ok=True)

    psql = testing.postgresql.Postgresql(
        base_dir=DB_DIR,
    )

    atexit.register(psql.stop)
    atexit.register(lambda: shutil.rmtree(DB_DIR))

    return psql


def _initdb():
    env = {
        **os.environ,
        'TESTING': '1',
        'PYTHON': sys.executable,
        'MOX_DB': settings.DATABASE,
        'MOX_DB_USER': settings.DB_USER,
        'MOX_DB_PASSWORD': settings.DB_PASSWORD,
    }

    with psycopg2.connect(psql().url()) as conn:
        conn.autocommit = True

        with conn.cursor() as curs:
            curs.execute('CREATE USER {} WITH SUPERUSER PASSWORD {!r}'.format(
                settings.DB_USER, settings.DB_PASSWORD,
            ))

            curs.execute('CREATE DATABASE {} WITH OWNER = {!r}'.format(
                settings.DATABASE, settings.DB_PASSWORD,
            ))

    with subprocess.Popen(
        [os.path.join(BASE_DIR, '..', 'db', 'mkdb.sh')],
        env=env,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        stdin=subprocess.DEVNULL,
    ) as proc:
        sql, errortext = proc.communicate()

    assert proc.returncode == 0, 'mkdb failed:\n\n' + errortext.decode()

    with psycopg2.connect(psql().url(
            database=settings.DATABASE,
            user=settings.DB_USER,
            password=settings.DB_PASSWORD,
    )) as conn:
        conn.autocommit = True

        with conn.cursor() as curs:
            curs.execute(sql)


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

    def __reset_db(self):
        with psycopg2.connect(self.db_url) as conn:
            conn.autocommit = True

            with conn.cursor() as curs:
                from oio_common.db_structure import DATABASE_STRUCTURE

                try:
                    curs.execute("TRUNCATE TABLE {} CASCADE".format(
                        ', '.join(sorted(DATABASE_STRUCTURE)),
                    ))
                except psycopg2.ProgrammingError:
                    pass

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

        for p in [
            mock.patch('settings.LOG_AMQP_SERVER', None),
            mock.patch('settings.DB_HOST', db_host,
                       create=True),
            mock.patch('settings.DB_PORT', db_port,
                       create=True),
            mock.patch(
                'oio_rest.db.pool',
                psycopg2.pool.SimpleConnectionPool(
                    1, 1,
                    database=settings.DATABASE,
                    user=settings.DB_USER,
                    password=settings.DB_PASSWORD,
                    host=db_host,
                    port=db_port,
                ),
            ),
        ]:
            p.start()
            self.addCleanup(p.stop)


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
