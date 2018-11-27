import os
import re
import subprocess

import tap.parser

from oio_rest.utils import test_support
import settings
from tests import util


class SQLTests(util.TestCase):
    def setUp(self):
        super().setUp()

        with self.db_cursor() as curs:
            curs.execute('CREATE EXTENSION IF NOT EXISTS "pgtap";')

            for dbfile in test_support.list_db_sql('tests'):
                with open(dbfile) as fp:
                    curs.execute(fp.read())

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
