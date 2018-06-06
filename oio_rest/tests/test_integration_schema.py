#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

import json
import flask_testing

from oio_rest import aktivitet
from oio_rest import app
from oio_rest import dokument
from oio_rest import indsats
from oio_rest import klassifikation
from oio_rest import log
from oio_rest import organisation
from oio_rest import sag
from oio_rest import tilstand


class TestSchemaEndPoints(flask_testing.TestCase):
    def create_app(self):
        app.app.config['TESTING'] = True
        return app.app

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
