import os
import re
import subprocess

from oio_rest.utils import test_support
import settings
from tests import util


class TestPLpgSQLTests(util.TestCase):
    """The output when a database test fails looks something like:

    E       AssertionError: 1 != 0 : 
    E       runtests('test'::name); .. 
    E       # Failed test 32: "test.test_json_cast_function"
    E       # Looks like you failed 1 test of 34
    E       Failed 1/34 subtests 
    E       
    E       Test Summary Report
    E       -------------------
    E       runtests('test'::name); (Wstat: 0 Tests: 34 Failed: 1)
    E         Failed test:  32
    E       Files=1, Tests=34,  1 wallclock secs ( 0.02 usr  0.00 sys +  0.03 cusr  0.00 csys =  0.05 CPU)
    E       Result: FAIL
    """
    def setUp(self):
        super().setUp()
        test_folder = os.path.join(os.path.dirname(__file__), "../../db/tests")

        with self.cursor() as curs:
            curs.execute('CREATE EXTENSION IF NOT EXISTS "pgtap";')
            for filename in os.listdir(test_folder):
                with open(os.path.join(test_folder, filename), "rt") as f:
                    curs.execute(f.read())

    def test_pg_prove(self):
        process = subprocess.Popen(
            "pg_prove --dbname %s --username %s --host %s --port %s --schema test" % (
                settings.DATABASE,
                settings.DB_USER,
                settings.DB_HOST,
                settings.DB_PORT,
            ),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            shell=True,
        )
        out, err = process.communicate()

        out = out.decode("utf-8")
        err = err.decode("utf-8")

        self.assertEqual(
            process.returncode,
            0,
            "%s\n%s" % (out, err),
        )

        with self.subTest("Verify that tests were found"):
            m = re.search(r"Tests=(\d+)", out)
            self.assertTrue(m)
            tests_found = int(m.group(1))
            self.assertTrue(tests_found > 0)
