#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

from __future__ import print_function

import json
import os
import pprint
import subprocess

import flask_testing
import mock
import testing.postgresql
import psycopg2


from oio_rest import app
from oio_rest import db
from oio_rest import settings

TESTS_DIR = os.path.dirname(__file__)
BASE_DIR = os.path.dirname(TESTS_DIR)
DATA_DIR = os.path.join(TESTS_DIR, 'data')
FIXTURE_DIR = os.path.join(TESTS_DIR, 'fixtures')


def jsonfile_to_dict(path):
    """
    Reads JSON from resources folder and converts to Python dictionary
    :param path: path to json resource
    :return: dictionary corresponding to the resource JSON
    """
    with open(os.path.join(BASE_DIR, path)) as f:
        return json.load(f)


def get_fixture(fixture_name):
    return jsonfile_to_dict(os.path.join(FIXTURE_DIR, fixture_name))


class TestCaseMixin(object):

    '''Base class for LoRA test cases with database access.
    '''

    maxDiff = None

    def create_app(self):
        app.app.config['DEBUG'] = False
        app.app.config['TESTING'] = True
        app.app.config['LIVESERVER_PORT'] = 0
        app.app.config['PRESERVE_CONTEXT_ON_EXCEPTION'] = False

        return app.app

    @classmethod
    def setUpClass(cls):
        super(TestCaseMixin, cls).setUpClass()

        cls.psql_factory = testing.postgresql.PostgresqlFactory(
            cache_initialized_db=True,
            on_initialized=cls.initdb
        )

    @classmethod
    def initdb(cls, psql):
        dsn = psql.dsn()

        conn = psycopg2.connect(**dsn)
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

            curs.execute(
                "ALTER DATABASE {} SET search_path TO actual_state, public"
                .format(
                    settings.DATABASE,
                ),
            )

        def do_psql(**kwargs):
            cmd = [
                'psql',
                '--user', dsn['user'],
                '--host', dsn['host'],
                '--port', str(dsn['port']),
                '--variable', 'ON_ERROR_STOP=1',
                '--output', os.devnull,
                '--no-password',
                '--quiet',
            ]

            for arg, value in kwargs.iteritems():
                cmd += '--' + arg, value,

            subprocess.check_call(cmd)

        do_psql(file=os.path.join(DATA_DIR, 'dump.sql'),
                dbname=settings.DB_USER)

    @classmethod
    def tearDownClass(cls):
        cls.psql_factory.clear_cache()

        super(TestCaseMixin, cls).tearDownClass()

    def setUp(self):
        super(TestCaseMixin, self).setUp()

        self.psql = self.psql_factory()

        dsn = self.psql.dsn()

        self.patches = [
            mock.patch('oio_rest.settings.LOG_AMQP_SERVER', None),
            mock.patch('oio_rest.settings.DB_PORT', dsn['port'],
                       create=True),
        ]

        for p in self.patches:
            p.start()
            self.addCleanup(p.stop)

        if hasattr(db.adapt, 'connection'):
            del db.adapt.connection

    def tearDown(self):
        super(TestCaseMixin, self).tearDown()

        self.psql.stop()

    def assertRequestResponse(self, path, expected, message=None,
                              status_code=None, drop_keys=(), **kwargs):
        '''Issue a request and assert that it succeeds (and does not
        redirect) and yields the expected output.

        **kwargs is passed directly to the test client -- see the
        documentation for werkzeug.test.EnvironBuilder for details.

        One addition is that we support a 'json' argument that
        automatically posts the given JSON data.

        '''
        message = message or 'request {!r} failed'.format(path)

        r = self._perform_request(path, **kwargs)

        actual = (
            json.loads(r.get_data(True))
            if r.mimetype == 'application/json'
            else r.get_data(True)
        )

        for k in drop_keys:
            try:
                actual.pop(k)
            except (IndexError, KeyError, TypeError):
                pass

        if actual != expected:
            pprint.pprint(actual)

        if status_code is None:
            self.assertLess(r.status_code, 300, message)
            self.assertGreaterEqual(r.status_code, 200, message)
        else:
            self.assertEqual(r.status_code, status_code, message)

        self.assertEqual(expected, actual, message)

    def assertRequestFails(self, path, code, message=None, **kwargs):
        '''Issue a request and assert that it succeeds (and does not
        redirect) and yields the expected output.

        **kwargs is passed directly to the test client -- see the
        documentation for werkzeug.test.EnvironBuilder for details.

        One addition is that we support a 'json' argument that
        automatically posts the given JSON data.
        '''
        message = message or "request {!r} didn't fail properly".format(path)

        r = self._perform_request(path, **kwargs)

        self.assertEqual(r.status_code, code, message)

    def _perform_request(self, path, **kwargs):
        if 'json' in kwargs:
            kwargs.setdefault('method', 'POST')
            kwargs.setdefault('data', json.dumps(kwargs.pop('json'), indent=2))
            kwargs.setdefault('headers', {'Content-Type': 'application/json'})

        return self.client.open(path, **kwargs)

    def assertRegistrationsEqual(self, expected, actual):
        def sort_inner_lists(obj):
            """Sort all inner lists and tuples by their JSON string value,
            recursively. This is quite stupid and slow, but works!

            This is purely to help comparison tests, as we don't care about the
            list ordering

            """
            if isinstance(obj, dict):
                return {
                    k: sort_inner_lists(v)
                    for k, v in obj.items()
                }
            elif isinstance(obj, (list, tuple)):
                return sorted(
                    map(sort_inner_lists, obj),
                    key=(lambda p: json.dumps(p, sort_keys=True)),
                )
            else:
                return obj

        # drop lora-generated timestamps & users
        expected.pop('fratidspunkt', None)
        expected.pop('tiltidspunkt', None)
        expected.pop('brugerref', None)

        actual.pop('fratidspunkt', None)
        actual.pop('tiltidspunkt', None)
        actual.pop('brugerref', None)

        # Sort all inner lists and compare
        return self.assertEqual(
            sort_inner_lists(expected),
            sort_inner_lists(actual))

    def assertQueryResponse(self, path, expected, **params):
        """Perform a request towards LoRa, and assert that it yields the
        expected output.

        Results are unpacked from the LoRa result structure and filtered of
        metadata before comparison

        **params are passed as part of the query string in the request.
        """

        r = self._perform_request(path, query_string=params).json

        results = r['results'][0]

        assert len(results) == 1
        registrations = results[0]['registreringer']

        if set(params.keys()) & {'registreretfra', 'registrerettil',
                                 'registreringstid'}:
            actual = registrations
        else:
            assert len(registrations) == 1
            actual = registrations[0]

        return self.assertRegistrationsEqual(expected, actual)

    def load_fixture(self, path, fixture_name, uuid=None):
        """Load a fixture, i.e. a JSON file in the 'fixtures' directory,
        into LoRA at the given path & UUID.
        """
        if uuid:
            path = "{}/{}".format(path, uuid)
            r = self._perform_request(path, method='PUT',
                                      json=get_fixture(fixture_name))
        else:
            r = self._perform_request(path, method='POST',
                                      json=get_fixture(fixture_name))

        self.assertLess(r.status_code, 300)
        self.assertGreaterEqual(r.status_code, 200)

        return r


class TestCase(TestCaseMixin, flask_testing.TestCase):
    pass
