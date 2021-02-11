# SPDX-FileCopyrightText: 2021- Magenta ApS
# SPDX-License-Identifier: MPL-2.0
from datetime import datetime, timedelta
from unittest import TestCase

from oio_rest.db.quick_query.search import InfiniteDatetime

INFINITY = 'infinity'
NINFINITY = '-infinity'


class TestInfiniteDatetime(TestCase):
    def test_parsing(self):
        base = datetime.now()
        base_str = base.isoformat()

        self.assertEqual(base_str, InfiniteDatetime.from_datetime(base).value)
        self.assertEqual(base_str, InfiniteDatetime.from_date_string(base_str).value)
        self.assertEqual(INFINITY, InfiniteDatetime.from_date_string(INFINITY).value)
        self.assertEqual(NINFINITY, InfiniteDatetime.from_date_string(NINFINITY).value)

    def test_comparison(self):
        base = datetime.now()

        ninf = InfiniteDatetime.from_date_string(NINFINITY)
        small = InfiniteDatetime.from_datetime(base)
        greater = InfiniteDatetime.from_datetime(base + timedelta(seconds=1))
        inf = InfiniteDatetime.from_date_string(INFINITY)

        # assert small to large
        self.assertTrue(ninf < small)
        self.assertTrue(ninf < greater)
        self.assertTrue(ninf < inf)

        self.assertTrue(small < greater)
        self.assertTrue(small < inf)

        self.assertTrue(greater < inf)

        # assert large to small
        self.assertFalse(inf < greater)
        self.assertFalse(inf < small)
        self.assertFalse(inf < ninf)

        self.assertFalse(greater < small)
        self.assertFalse(greater < ninf)

        self.assertFalse(small < ninf)

        # illegal asserts
        with self.assertRaises(ValueError):
            ninf < ninf
        with self.assertRaises(ValueError):
            inf < inf

        # Type asserts
        with self.assertRaises(TypeError):
            small < base
        with self.assertRaises(TypeError):
            small < base.isoformat()
