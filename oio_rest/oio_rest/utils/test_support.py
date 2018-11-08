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


def _get_db_setup_sql(db_name, db_user):
    """Return the postgresql + pl/pgsql code necessary for our database
    to work.

    Brave souls can find db/mkdb.sh in the git history to see what this
    function replaces."""

    init = """
    GRANT ALL ON DATABASE "{db_name}" TO "{db_user}";

    CREATE SCHEMA actual_state AUTHORIZATION "{db_user}";

    ALTER DATABASE "{db_name}" SET search_path TO actual_state,public;
    ALTER DATABASE "{db_name}" SET DATESTYLE to 'ISO, YMD';
    ALTER DATABASE "{db_name}" SET INTERVALSTYLE to 'sql_standard';

    CREATE SCHEMA test AUTHORIZATION "{db_user}";
    """.format(db_name=db_name, db_user=db_user)

    def listdir(dirname):
        # os.listdir() but with prefix
        return [os.path.join(dirname, filename)
                for filename in os.listdir(dirname)]

    # <mess>
    # this mess is necessary because the db relies on a particular order
    # first its needs a bunch of functions "funcs1"
    # then it needs some of the templates "templates1"
    # then the remaining functions "funcs2"
    # and finally "templates1"

    # 5$ to anyone who can come up with a better way to express our
    #     dependency graph...
    template1_types = [
        "dbtyper-specific",
        "tbls-specific",
        "_remove_nulls_in_array",
    ]
    template2_types = [
        "_as_get_prev_registrering",
        "_as_create_registrering",
        "as_update",
        "as_create_or_import",
        "as_list",
        "as_read",
        "as_search",
        "json-cast-functions",
        "_as_sorted",
        "_as_filter_unauth",
    ]
    def template_sort_key(template_name):
        for i, template_type in enumerate(template1_types + template2_types):
            if template_type in template_name:
                return i, template_name
        raise ValueError("template name invalid: ", template_name)

    def is_template1(template):
        for template_type in template1_types:
            if template_type in template:
                return True
        return False

    templates = listdir('../db/db-templating/generated-files')
    templates.sort(key=template_sort_key)
    templates1 = list(filter(is_template1, templates))
    templates2 = list(set(templates) ^ set(templates1))
    funcs1 = [
        "../db/funcs/_index_helper_funcs.sql",
        "../db/funcs/_subtract_tstzrange.sql",
        "../db/funcs/_subtract_tstzrange_arr.sql",
        "../db/funcs/_as_valid_registrering_livscyklus_transition.sql",
        "../db/funcs/_as_search_match_array.sql",
        "../db/funcs/_as_search_ilike_array.sql",
        "../db/funcs/_json_object_delete_keys.sql",
        "../db/funcs/_create_notify.sql",
    ]
    funcs2 = list(set(listdir('../db/funcs')) ^ set(funcs1))

    files = [
        *listdir('../db/basis'),
        *funcs1,
        *templates1,
        *funcs2,
        *templates2,
        *listdir('../db/tests'),
    ]
    # </mess>

    file_contents = []
    for filename in files:
        with open(filename, 'rt') as f:
            file_contents.append(f.read())
    return init + '\n'.join(file_contents)


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

    sql = _get_db_setup_sql(settings.DATABASE, settings.DB_USER)
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
