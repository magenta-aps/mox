# SPDX-FileCopyrightText: 2019-2020 Magenta ApS
# SPDX-License-Identifier: MPL-2.0


import json
import tempfile

from oio_rest import app
from oio_rest.db import db_structure
from tests.util import ExtTestCase


class Tests(ExtTestCase):
    def create_app(self):
        return app

    def get_fields(self):
        return db_structure.REAL_DB_STRUCTURE["organisationfunktion"]

    def test_patching_with_dict(self):
        orig = {
            "egenskaber": ["brugervendtnoegle", "funktionsnavn", "integrationsdata"]
        }

        self.assertEqual(
            self.get_fields()["attributter"],
            orig,
        )

        with self.extend_db_struct(
            {
                "organisationfunktion": {
                    "attributter": {
                        "fætre": [
                            "hest",
                            "høg",
                        ],
                    },
                },
            }
        ):
            self.assertEqual(
                self.get_fields()["attributter"],
                {
                    **orig,
                    "fætre": ["hest", "høg"],
                },
            )

        self.assertEqual(
            self.get_fields()["attributter"],
            orig,
        )

    def test_patching_with_file(self):
        orig = {
            "egenskaber": ["brugervendtnoegle", "funktionsnavn", "integrationsdata"]
        }

        self.assertEqual(
            self.get_fields()["attributter"],
            orig,
        )

        with tempfile.NamedTemporaryFile("w+t") as fp:
            json.dump(
                {
                    "organisationfunktion": {
                        "attributter": {
                            "fætre": [
                                "hest",
                                "høg",
                            ],
                        },
                    },
                },
                fp,
            )
            fp.flush()

            with self.extend_db_struct(fp.name):
                self.assertEqual(
                    self.get_fields()["attributter"],
                    {
                        **orig,
                        "fætre": ["hest", "høg"],
                    },
                )

        self.assertEqual(
            self.get_fields()["attributter"],
            orig,
        )

    def test_patching_order(self):
        with self.extend_db_struct(
            {
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
            }
        ):
            self.assertEqual(
                list(self.get_fields()["attributter"]),
                ["egenskaber", "fætre"],
            )

            self.assertEqual(
                list(self.get_fields()["tilstande"]),
                ["gyldighed", "høj"],
            )

        with self.extend_db_struct(
            {
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
            }
        ):
            self.assertEqual(
                list(self.get_fields()["attributter"]),
                ["egenskaber", "xyzzy"],
            )

            self.assertEqual(
                list(self.get_fields()["tilstande"]),
                ["gyldighed", "zzz"],
            )

        with self.extend_db_struct(
            {
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
            }
        ):
            self.assertEqual(
                list(self.get_fields()["attributter"]),
                ["egenskaber", "aardvark"],
            )

            self.assertEqual(
                list(self.get_fields()["tilstande"]),
                ["gyldighed", "aabenraa"],
            )
