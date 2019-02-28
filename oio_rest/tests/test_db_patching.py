# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


import json
import tempfile

import flask_testing

from oio_rest import settings
from oio_rest import app
from oio_rest.utils import test_support


class Tests(flask_testing.TestCase):
    def create_app(self):
        return app.app

    def get_fields(self):
        return settings.REAL_DB_STRUCTURE['organisationfunktion']

    def test_patching_with_dict(self):
        orig = {
            "egenskaber": [
                "brugervendtnoegle",
                "funktionsnavn",
                "integrationsdata"
            ]
        }

        self.assertEqual(
            self.get_fields()['attributter'],
            orig,
        )

        with test_support.extend_db_struct({
                "organisationfunktion": {
                    "attributter": {
                        "fætre": [
                            "hest",
                            "høg",
                        ],
                    },
                },
        }):
            self.assertEqual(
                self.get_fields()['attributter'],
                {
                    **orig,
                    'fætre': ['hest', 'høg'],
                })

        self.assertEqual(
            self.get_fields()['attributter'],
            orig,
        )

    def test_patching_with_file(self):
        orig = {
            "egenskaber": [
                "brugervendtnoegle",
                "funktionsnavn",
                "integrationsdata"
            ]
        }

        self.assertEqual(
            self.get_fields()['attributter'],
            orig,
        )

        with tempfile.NamedTemporaryFile('w+t') as fp:
            json.dump({
                "organisationfunktion": {
                    "attributter": {
                        "fætre": [
                            "hest",
                            "høg",
                        ],
                    },
                },
            }, fp)
            fp.flush()

            with test_support.extend_db_struct(fp.name):
                self.assertEqual(
                    self.get_fields()['attributter'],
                    {
                        **orig,
                        'fætre': ['hest', 'høg'],
                    },
                )

        self.assertEqual(
            self.get_fields()['attributter'],
            orig,
        )

    def test_patching_order(self):
        with test_support.extend_db_struct({
                "organisationfunktion": {
                    "attributter": {
                        "fætre": [
                            "hest",
                            "høg",
                        ],
                    },
                    "tilstande": {
                        "høj": [
                            "Nej",
                            "Ja",
                        ],
                    },
                },
        }):
            self.assertEqual(
                list(self.get_fields()['attributter']),
                ['egenskaber', 'fætre'],
            )

            self.assertEqual(
                list(self.get_fields()['tilstande']),
                ['gyldighed', 'høj'],
            )

        with test_support.extend_db_struct({
                "organisationfunktion": {
                    "attributter": {
                        "xyzzy": [
                            "dood",
                            "daad",
                        ],
                    },
                    "tilstande": {
                        "zzz": [
                            "baab",
                            "beeb",
                        ],
                    },
                },
        }):
            self.assertEqual(
                list(self.get_fields()['attributter']),
                ['egenskaber', 'xyzzy'],
            )

            self.assertEqual(
                list(self.get_fields()['tilstande']),
                ['gyldighed', 'zzz'],
            )

        with test_support.extend_db_struct({
                "organisationfunktion": {
                    "attributter": {
                        "aardvark": [
                            "laal",
                            "lool",
                        ],
                    },
                    "tilstande": {
                        "aabenraa": [
                            "aach",
                            "heen",
                        ],
                    },
                },
        }):
            self.assertEqual(
                list(self.get_fields()['attributter']),
                ['egenskaber', 'aardvark'],
            )

            self.assertEqual(
                list(self.get_fields()['tilstande']),
                ['gyldighed', 'aabenraa'],
            )
