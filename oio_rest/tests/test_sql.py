# SPDX-FileCopyrightText: 2018-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


import os
import pathlib
import unittest

import tap.parser

from oio_rest import config
from oio_rest.db import db_templating, get_connection
from tests import util
from tests.util import DBTestCase


class SQLTests(DBTestCase):
    def setUp(self):
        super().setUp()
        with get_connection() as conn, conn.cursor() as curs:
            curs.execute('CREATE EXTENSION "pgtap";')

            curs.execute(
                'CREATE SCHEMA test AUTHORIZATION "{}";'.format(
                    config.get_settings().db_user,
                ),
            )

            for dbfile in pathlib.Path(util.TESTS_DIR).glob("sql/*.sql"):
                curs.execute(dbfile.read_text())

    def tearDown(self):
        super().setUp()

        with get_connection() as conn, conn.cursor() as curs:
            curs.execute("DROP SCHEMA test CASCADE")
            curs.execute('DROP EXTENSION IF EXISTS "pgtap" CASCADE;')

    def test_pgsql(self):
        with get_connection() as conn, conn.cursor() as curs:
            curs.execute("SELECT * FROM runtests ('test'::name)")

            self.assertGreater(curs.rowcount, 0)

            # tap.py doesn't support subtests yet, so strip the line
            # see https://github.com/python-tap/tappy/issues/71
            #
            # please note that the tuple unpacking below is
            # deliberate; we're iterating over over a cursor
            # containing single-item rows
            taptext = "\n".join(line.strip() for (line,) in curs)

        for result in tap.parser.Parser().parse_text(taptext):
            if result.category == "test":
                print(result)

                with self.subTest(result.description):
                    if result.skip:
                        raise unittest.SkipTest()
                    elif not result.ok:
                        self.fail(result.diagnostics or result.description)


class TextTests(unittest.TestCase):
    def test_sql_unchanged(self):
        """Check that the sql have not changed from last commit. The intention
        of the test is not to force sql stagenation, but to inform the
        developers of sql changes in commits by updating `db-dump.sql`.

        Update with `python3 -m oio_rest sql > db-dump.sql`
        """

        SQL_FIXTURE = os.path.join(util.FIXTURE_DIR, "db-dump.sql")

        expected_path = pathlib.Path(SQL_FIXTURE)
        actual = "\n".join(db_templating.get_sql()) + "\n"
        expected = expected_path.read_text()

        self.assertEqual(
            expected,
            actual,
            "SQL changed. Update with `python3 -m oio_rest sql > {}`".format(
                expected_path
            ),
        )
