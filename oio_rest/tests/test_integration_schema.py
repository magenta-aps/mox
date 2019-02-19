#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

import json
import os

import flask_testing

from oio_rest import aktivitet
from oio_rest import app
from oio_rest import dokument
from oio_rest import indsats
from oio_rest import klassifikation
from oio_rest import log
from oio_rest import oio_rest
from oio_rest import organisation
from oio_rest import sag
from oio_rest import tilstand

from . import util


class TestSchemaEndPoints(flask_testing.TestCase):
    def create_app(self):
        app.app.config['TESTING'] = True
        return app.app

    def test_schemas_unchanged(self):
        """
        Check that the schema endpoints for the classes in the given hierarchy
        respond with HTTP status code 200 and return JSON.
        :param hierarchy: The hierarchy to check, e.g. SagsHierarki,...
        """
        # Careful now - no logic in the test code!

        expected = util.get_fixture('schemas.json')

        actual = {
            cls.__name__: cls.get_schema().json
            for hier in oio_rest.HIERARCHIES
            for cls in hier._classes
        }
        actual_path = os.path.join(util.FIXTURE_DIR, 'schemas.json.new')

        with open(actual_path, 'wt') as fp:
            json.dump(actual, fp, indent=2, sort_keys=True)

        self.assertEqual(expected, actual,
                         'schemas changed, see {}'.format(actual_path))

    def assertSchemaOK(self, hierarchy):
        """
        Check that the schema endpoints for the classes in the given hierarchy
        respond with HTTP status code 200 and return JSON.
        :param hierarchy: The hierarchy to check, e.g. SagsHierarki,...
        """
        # Careful now - no logic in the test code!

        for obj in hierarchy._classes:
            url = '/{}/{}/schema'.format(hierarchy._name.lower(),
                                         obj.__name__.lower())
            r = self.client.get(url)
            self.assertEqual(200, r.status_code)
            json.loads(r.data.decode('utf-8'))

    def test_aktivitet_hierarchy(self):
        self.assertSchemaOK(aktivitet.AktivitetsHierarki)

    def test_dokument_hierarchy(self):
        self.assertSchemaOK(dokument.DokumentHierarki)

    def test_indsats_hierarchy(self):
        self.assertSchemaOK(indsats.IndsatsHierarki)

    def test_klassifikation_hierarchy(self):
        self.assertSchemaOK(klassifikation.KlassifikationsHierarki)

    def test_log_hierarchy(self):
        self.assertSchemaOK(log.LogHierarki)

    def test_organisation_hierarchy(self):
        self.assertSchemaOK(organisation.OrganisationsHierarki)

    def test_sag_hierarchy(self):
        self.assertSchemaOK(sag.SagsHierarki)

    def test_tilstand_hierarchy(self):
        self.assertSchemaOK(tilstand.TilstandsHierarki)
