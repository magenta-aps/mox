#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

from tests import util
from tests.util import DBTestCase


class Tests(DBTestCase):
    def test_import(self):
        objid = self.load_fixture('/klassifikation/klasse',
                                  'klasse_opret.json')

        expected = {
            "note": "Ny klasse",
            "attributter": {
                "klasseegenskaber": [
                    {
                        "omfang": "Magenta",
                        "beskrivelse": "Organisatorisk funktion",
                        "brugervendtnoegle": "ORGFUNK",
                        "titel": "XYZ",
                        "virkning": {
                            "from_included": True,
                            "aktoerref":
                            "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "aktoertypekode": "Bruger",
                            "to_included": False,
                            "from": "2014-05-19 12:02:32+02",
                            "to": "infinity"
                        },
                        "retskilde": "Ja",
                        "soegeord": [
                            {
                                "beskrivelse": "\u00e6Vores kunde",
                                "soegeordidentifikator": "KL",
                                "soegeordskategori": "info"
                            },
                            {
                                "beskrivelse": "Vores firma",
                                "soegeordidentifikator": "Magenta\u00f8",
                                "soegeordskategori": "info"
                            }
                        ],
                        "eksempel": "Hierarkisk"
                    }
                ]
            },
            "relationer": {
                "ansvarlig": [
                    {
                        "objekttype": "Bruger",
                        "uuid": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                        "virkning": {
                            "from_included": True,
                            "aktoerref":
                            "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "aktoertypekode": "Bruger",
                            "to_included": False,
                            "to": "infinity",
                            "from": "2014-05-19 12:02:32+02",
                            "notetekst": "Nothing to see here!"
                        }
                    }
                ],
                "redaktoerer": [
                    {
                        "objekttype": "Bruger",
                        "uuid": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                        "virkning": {
                            "from_included": True,
                            "aktoerref":
                            "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "aktoertypekode": "Bruger",
                            "to_included": False,
                            "to": "infinity",
                            "from": "2015-05-19 12:02:32+02",
                            "notetekst": "Nothing to see here!"
                        }
                    },
                    {
                        "objekttype": "Bruger",
                        "uuid": "ef2713ee-1a38-4c23-8fcb-3c4331262194",
                        "virkning": {
                            "from_included": True,
                            "aktoerref":
                            "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "aktoertypekode": "Bruger",
                            "to_included": False,
                            "to": "infinity",
                            "from": "2014-05-19 12:02:32+02",
                            "notetekst": "Nothing to see here!"
                        }
                    }
                ]
            },
            "tilstande": {
                "klassepubliceret": [
                    {
                        "publiceret": "Publiceret",
                        "virkning": {
                            "from_included": True,
                            "aktoerref":
                            "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "aktoertypekode": "Bruger",
                            "to_included": False,
                            "to": "infinity",
                            "from": "2014-05-19 12:02:32+02",
                            "notetekst": "Nothing to see here!"
                        }
                    }
                ]
            },
            "livscykluskode": "Opstaaet"
        }

        self.assertQueryResponse('/klassifikation/klasse', expected,
                                 uuid=objid)

    def test_edit_put(self):
        objid = self.load_fixture('/klassifikation/klasse',
                                  'klasse_opret.json')

        self.assertRequestResponse(
            '/klassifikation/klasse/{}'.format(objid),
            {
                'uuid': objid,
            },
            json=util.get_fixture('klasse_opdater_put.json'),
            method='PUT'
        )
        expected = {
            'note': 'Overskriv klasse med  nye perioder mv',
            'attributter': {
                'klasseegenskaber': [
                    {
                        'beskrivelse': 'Klasse',
                        'brugervendtnoegle': 'KLASSE',
                        'eksempel': 'Hierarkisk',
                        'omfang': 'Magenta',
                        'retskilde': 'Nej',
                        'soegeord': [
                            {
                                'beskrivelse': 'Vores firma',
                                'soegeordidentifikator': 'Magenta',
                                'soegeordskategori': 'info'
                            },
                            {
                                'beskrivelse': 'Vores kunde',
                                'soegeordidentifikator': 'KL',
                                'soegeordskategori': 'info'
                            }
                        ],
                        'titel': 'XYZ',
                        'virkning': {
                            'aktoerref':
                            'ddc99abd-c1b0-48c2-aef7-74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2016-05-19 12:02:32+02',
                            'from_included': True,
                            'to': 'infinity',
                            'to_included': False
                        }
                    }
                ]
            },
            'livscykluskode': 'Rettet',
            'note': 'Overskriv klasse med  nye perioder mv',
            'relationer': {
                'ansvarlig': [
                    {
                        'objekttype': 'Bruger',
                        'uuid': 'ddc99abd-c1b0-48c2-aef7-74fea841adae',
                        'virkning': {
                            'aktoerref':
                            'ddc99abd-c1b0-48c2-aef7-74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2016-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False
                        }
                    }
                ],
                'redaktoerer': [
                    {
                        'objekttype': 'Bruger',
                        'uuid': 'ddc99abd-c1b0-48c2-aef7-74fea841adae',
                        'virkning': {
                            'aktoerref':
                            'ddc99abd-c1b0-48c2-aef7-74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2016-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False
                        }
                    },
                    {
                        'objekttype': 'Bruger',
                        'uuid': 'ef2713ee-1a38-4c23-8fcb-3c4331262194',
                        'virkning': {
                            'aktoerref':
                            'ddc99abd-c1b0-48c2-aef7-74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2016-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False
                        }
                    }
                ]
            },
            'tilstande': {
                'klassepubliceret': [
                    {
                        'publiceret': 'Publiceret',
                        'virkning': {
                            'aktoerref':
                            'ddc99abd-c1b0-48c2-aef7-74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2016-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False
                        }
                    }
                ]
            }
        }

        self.assertQueryResponse(
            '/klassifikation/klasse',
            expected,
            uuid=objid,
        )

    def test_edit(self):
        objid = self.load_fixture('/klassifikation/klasse',
                                  'klasse_opret.json')

        self.assertRequestResponse(
            '/klassifikation/klasse/{}'.format(objid),
            {
                'uuid': objid,
            },
            json=util.get_fixture('klasse_opdater.json'),
            method='PATCH'
        )

        expected = {
            "relationer": {
                "ansvarlig": [
                    {
                        "uuid": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                        "objekttype": "Bruger",
                        "virkning": {
                            "aktoerref":
                            "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "to_included": False,
                            "aktoertypekode": "Bruger",
                            "to": "infinity",
                            "notetekst": "Nothing to see here!",
                            "from_included": True,
                            "from": "2014-05-19 12:02:32+02"
                        }
                    }
                ],
                "redaktoerer": [
                    {
                        "uuid": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                        "objekttype": "Bruger",
                        "virkning": {
                            "aktoerref":
                            "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "to_included": False,
                            "aktoertypekode": "Bruger",
                            "to": "infinity",
                            "notetekst": "Nothing to see here!",
                            "from_included": True,
                            "from": "2015-05-19 12:02:32+02"
                        }
                    },
                    {
                        "uuid": "ef2713ee-1a38-4c23-8fcb-3c4331262194",
                        "objekttype": "Bruger",
                        "virkning": {
                            "aktoerref":
                            "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "to_included": False,
                            "aktoertypekode": "Bruger",
                            "to": "infinity",
                            "notetekst": "Nothing to see here!",
                            "from_included": True,
                            "from": "2014-05-19 12:02:32+02"
                        }
                    }
                ]
            },
            "attributter": {
                "klasseegenskaber": [
                    {
                        "omfang": "Magenta",
                        "beskrivelse": "Organisatorisk funktion",
                        "retskilde": "Ja",
                        "virkning": {
                            "aktoerref":
                            "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "to_included": False,
                            "aktoertypekode": "Bruger",
                            "to": "infinity",
                            "from_included": True,
                            "from": "2014-05-22 12:02:32+02"
                        },
                        "brugervendtnoegle": "ORGFUNK",
                        "soegeord": [
                            {
                                "beskrivelse": "med",
                                "soegeordidentifikator": "hej",
                                "soegeordskategori": "dig"
                            }
                        ],
                        "eksempel": "Hierarkisk",
                        "titel": "XYZ"
                    }
                ]
            },
            "brugerref": "42c432e8-9c4a-11e6-9f62-873cf34a735f",
            "tilstande": {
                "klassepubliceret": [
                    {
                        "publiceret": "Publiceret",
                        "virkning": {
                            "aktoerref":
                            "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "to_included": False,
                            "aktoertypekode": "Bruger",
                            "to": "infinity",
                            "notetekst": "Nothing to see here!",
                            "from_included": True,
                            "from": "2014-05-19 12:02:32+02"
                        }
                    }
                ]
            },
            "livscykluskode": "Rettet",
            "note": "Opdater klasse"
        }

        self.assertQueryResponse(
            '/klassifikation/klasse',
            expected,
            uuid=objid,
        )

    def test_deleting_nothing(self):
        msg = (
            'No Klasse with ID 00000000-0000-0000-0000-000000000000 found.'
        )

        self.assertRequestResponse(
            '/klassifikation/klasse'
            '/00000000-0000-0000-0000-000000000000',
            {
                'message': msg,
            },
            method='DELETE',
            status_code=404,
        )

    def test_deleting_something(self):
        objid = self.load_fixture('/klassifikation/klasse',
                                  'klasse_opret.json')

        r = self.client.delete(
            '/klassifikation/klasse/' + objid,
        )

        self.assertEqual(r.status_code, 202)
        self.assertEqual(r.status, '202 ACCEPTED')
        self.assertEqual(r.json, {'uuid': objid})

        # once more for prince canut!
        self.assertRequestResponse(
            '/klassifikation/klasse/' + objid,
            {
                'uuid': objid,
            },
            status_code=202,
            method='DELETE',
        )

    def test_bad_import(self):
        '''import a class into an organisation -- not expected to work'''
        data = util.get_fixture('klasse_opret.json')

        self.assertRequestFails(
            '/klassifikation/klassifikation',
            400,
            method='POST',
            json=data,
        )

    def test_lowercase_state(self):
        objid = self.load_fixture('/klassifikation/klasse',
                                  'klasse_opret.json')

        self.assertRequestFails(
            '/klassifikation/klasse/' + objid,
            400,
            method='PATCH',
            json={
                'tilstande': {
                    'publiceret': [
                        {
                            "publiceret": "publiceret",
                            "virkning": {
                                "from": "2015-01-01",
                                "to": "2016-01-01",
                                "notetekst": "odd case!"
                            },
                        },
                    ],
                },
            })

        self.assertRequestFails(
            '/klassifikation/klasse/' + objid,
            400,
            method='PATCH',
            json={
                'tilstande': {
                    'publiceret': [
                        {
                            "publiceret": "iKKEpUBLICERET",
                            "virkning": {
                                "from": "2016-01-01",
                                "to": "2017-01-01",
                                "notetekst": "lowercase!"
                            }
                        }
                    ]
                }
            },
        )
