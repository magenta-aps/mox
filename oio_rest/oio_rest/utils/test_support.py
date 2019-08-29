#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

import contextlib
import copy
import os
import types
import typing

import click
import mock
import psycopg2
import psycopg2.extensions
import psycopg2.pool

from oio_rest import app, settings
from oio_rest.db import db_structure

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
    ]

    if isinstance(new, types.ModuleType):
        patches.append(mock.patch('oio_rest.db.db_structure.REAL_DB_STRUCTURE',
                       new=new.REAL_DB_STRUCTURE))
    else:
        patches.append(mock.patch('oio_rest.db.db_structure.REAL_DB_STRUCTURE',
                       new=new))

    with contextlib.ExitStack() as stack:
        for patch in patches:
            stack.enter_context(patch)

        yield


@contextlib.contextmanager
def extend_db_struct(new: dict):
    '''Context manager for extending db_structures'''

    dbs = copy.deepcopy(db_structure.DATABASE_STRUCTURE)
    real_dbs = copy.deepcopy(db_structure.REAL_DB_STRUCTURE)

    patches = [
        mock.patch('oio_rest.db.db_helpers._attribute_fields', {}),
        mock.patch('oio_rest.db.db_helpers._attribute_names', {}),
        mock.patch('oio_rest.db.db_helpers._relation_names', {}),
        mock.patch('oio_rest.validate.SCHEMAS', {}),
        mock.patch('oio_rest.db.db_structure.DATABASE_STRUCTURE', new=dbs),
        mock.patch('oio_rest.db.db_structure.REAL_DB_STRUCTURE', new=real_dbs),
    ]

    with contextlib.ExitStack() as stack:
        for patch in patches:
            stack.enter_context(patch)

        db_structure.load_db_extensions(new)

        yield


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

        app.run(**kwargs)


if __name__ == '__main__':
    run_with_db()
