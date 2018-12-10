# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import os
import pathlib
import re
import subprocess
import sys

import tap.parser

from oio_rest.utils import test_support
from oio_rest import db_templating
import settings
from tests import util

SQL_FIXTURE = os.path.join(util.FIXTURE_DIR, 'db-dump.sql')


class SQLTests(util.TestCase):
    def setUp(self):
        super().setUp()

        with self.db_cursor() as curs:
            curs.execute('CREATE EXTENSION "pgtap";')

            curs.execute(
                'CREATE SCHEMA test AUTHORIZATION "{}";'.format(
                    settings.DB_USER,
                ),
            )

            for dbfile in pathlib.Path(util.TESTS_DIR).glob("sql/*.sql"):
                curs.execute(dbfile.read_text())

    def tearDown(self):
        super().setUp()

        with self.db_cursor() as curs:
            curs.execute('DROP SCHEMA test CASCADE')
            curs.execute('DROP EXTENSION IF EXISTS "pgtap" CASCADE;')

    def test_pgsql(self):
        with self.db_cursor() as curs:
            curs.execute("SELECT * FROM runtests ('test'::name)")

            self.assertGreater(curs.rowcount, 0)

            # tap.py doesn't support subtests yet, so strip the line
            # see https://github.com/python-tap/tappy/issues/71
            #
            # please note that the tuple unpacking below is
            # deliberate; we're iterating over over a cursor
            # containing single-item rows
            taptext = '\n'.join(line.strip() for (line,) in curs)

        for result in tap.parser.Parser().parse_text(taptext):
            if result.category == 'test':
                print(result)

                with self.subTest(result.description):
                    if result.skip:
                        raise unittest.SkipTest()
                    elif not result.ok:
                        self.fail(result.diagnostics or
                                  result.description)

    def test_sql_unchanged(self):
        expected_path = pathlib.Path(SQL_FIXTURE)
        actual_path = expected_path.with_name(expected_path.name + '.new')

        actual_path.write_text('\n'.join(db_templating.render_templates()))

        self.assertEqual(
            expected_path.read_text(),
            actual_path.read_text(),
            'contents changed -- new dump is in {}'.format(actual_path),
        )
