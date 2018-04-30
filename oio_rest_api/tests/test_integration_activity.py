#
# Copyright (c) 2017-2018, Magenta ApS
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

from __future__ import unicode_literals

from tests import util


class Tests(util.TestCase):
    def test_import(self):
        objid = self.load_fixture('/aktivitet/aktivitet',
                                  'aktivitet_opret.json')

        expected = {
            'attributter': {
                'aktivitetegenskaber': [
                    {
                        'aktivitetnavn': 'XYZ',
                        'beskrivelse': 'Jogging',
                        'brugervendtnoegle': 'JOGGING',
                        'formaal': 'Ja',
                        'sluttidspunkt': '2016-05-19T16:02:32+02:00',
                        'starttidspunkt': '2014-05-19T14:02:32+02:00',
                        'tidsforbrug': '2:00:00',
                        'virkning': {
                            'aktoerref': 'ddc99abd-c1b0-48c2-aef7-'
                            '74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2014-05-19 12:02:32+02',
                            'from_included': True,
                            'to': 'infinity',
                            'to_included': False,
                        },
                    },
                ],
            },
            'brugerref': '42c432e8-9c4a-11e6-9f62-873cf34a735f',
            'note': 'Ny aktivitet',
            'livscykluskode': 'Opstaaet',
            'relationer': {
                'ansvarlig': [
                    {
                        'aktoerattr': {
                            'accepteret': 'foreloebigt',
                            'obligatorisk': 'valgfri',
                            'repraesentation_uuid': '0e3ed41a-08f2-4967-'
                            '8689-dce625f93029',
                        },
                        'objekttype': 'Bruger',
                        'uuid': 'abcdeabd-c1b0-48c2-aef7-74fea841adae',
                        'virkning': {
                            'aktoerref': 'ddc99abd-c1b0-48c2-aef7-'
                            '74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2014-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False,
                        },
                    },
                ],
                'deltager': [
                    {
                        'aktoerattr': {
                            'accepteret': 'foreloebigt',
                            'obligatorisk': 'valgfri',
                            'repraesentation_uuid': '0e3ed41a-08f2-4967-'
                            '8689-dce625f93029',
                        },
                        'indeks': 1,
                        'objekttype': 'Bruger',
                        'uuid': '123deabd-c1b0-48c2-aef7-74fea841adae',
                        'virkning': {
                            'aktoerref': 'ddc99abd-c1b0-48c2-aef7-'
                            '74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2014-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False,
                        },
                    },
                    {
                        'aktoerattr': {
                            'accepteret': 'foreloebigt',
                            'obligatorisk': 'valgfri',
                            'repraesentation_uuid': '0123d41a-08f2-4967-'
                            '8689-dce625f93029',
                        },
                        'indeks': 2,
                        'objekttype': 'Bruger',
                        'uuid': '22345abd-c1b0-48c2-aef7-74fea841adae',
                        'virkning': {
                            'aktoerref': 'ddc99abd-c1b0-48c2-aef7-'
                            '74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2014-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False,
                        },
                    },
                ],
            },
            'tilstande': {
                'aktivitetpubliceret': [
                    {
                        'publiceret': 'Publiceret',
                        'virkning': {
                            'aktoerref': 'ddc99abd-c1b0-48c2-aef7-'
                            '74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2014-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False,
                        },
                    },
                ],
                'aktivitetstatus': [
                    {
                        'status': 'Aktiv',
                        'virkning': {
                            'aktoerref': 'ddc99abd-c1b0-48c2-aef7-'
                            '74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2014-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False,
                        },
                    },
                ],
            },
        }

        self.assertQueryResponse('/aktivitet/aktivitet', expected, uuid=objid)

    def test_edit(self):
        objid = self.load_fixture('/aktivitet/aktivitet',
                                  'aktivitet_opret.json')

        self.assertRequestResponse(
            '/aktivitet/aktivitet/{}'.format(objid),
            {
                'uuid': objid,
            },
            json=util.get_fixture('aktivitet_opdater.json'),
            method='PUT',
        )

        expected = {
            'attributter': {
                'aktivitetegenskaber': [
                    {
                        'aktivitetnavn': 'XYZ',
                        'beskrivelse': 'Jogging',
                        'brugervendtnoegle': 'JOGGING',
                        'formaal': 'Ja',
                        'sluttidspunkt': '2016-05-19T16:02:32+02:00',
                        'starttidspunkt': '2014-05-19T14:02:32+02:00',
                        'tidsforbrug': '0',
                        'virkning': {
                            'aktoerref': 'ddc99abd-c1b0-48c2-aef7-'
                            '74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2016-05-19 12:02:32+02',
                            'from_included': True,
                            'to': 'infinity',
                            'to_included': False,
                        },
                    },
                ],
            },
            'livscykluskode': 'Rettet',
            'note': 'Opdatering',
            'relationer': {
                'ansvarlig': [
                    {
                        'objekttype': 'Bruger',
                        'uuid': 'abcdeabd-c1b0-48c2-aef7-74fea841adae',
                        'virkning': {
                            'aktoerref': 'ddc99abd-c1b0-48c2-aef7-'
                            '74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2016-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False,
                        },
                    },
                ],
                'deltager': [
                    {
                        'aktoerattr': {
                            'accepteret': 'foreloebigt',
                            'obligatorisk': 'valgfri',
                            'repraesentation_uuid': '0e3ed41a-08f2-4967-8689-'
                            'dce625f93029',
                        },
                        'indeks': 1,
                        'objekttype': 'Bruger',
                        'uuid': '123deabd-c1b0-48c2-aef7-74fea841adae',
                        'virkning': {
                            'aktoerref': 'ddc99abd-c1b0-48c2-aef7-'
                            '74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2014-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False,
                        },
                    },
                    {
                        'aktoerattr': {
                            'accepteret': 'foreloebigt',
                            'obligatorisk': 'valgfri',
                            'repraesentation_uuid': '0123d41a-08f2-4967-8689-'
                            'dce625f93029',
                        },
                        'indeks': 2,
                        'objekttype': 'Bruger',
                        'uuid': '22345abd-c1b0-48c2-aef7-74fea841adae',
                        'virkning': {
                            'aktoerref': 'ddc99abd-c1b0-48c2-aef7-'
                            '74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2014-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False,
                        },
                    },
                ],
            },
            'tilstande': {
                'aktivitetpubliceret': [
                    {
                        'publiceret': 'Publiceret',
                        'virkning': {
                            'aktoerref': 'ddc99abd-c1b0-48c2-aef7-'
                            '74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2014-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False,
                        },
                    },
                ],
                'aktivitetstatus': [
                    {
                        'status': 'Aktiv',
                        'virkning': {
                            'aktoerref': 'ddc99abd-c1b0-48c2-aef7-'
                            '74fea841adae',
                            'aktoertypekode': 'Bruger',
                            'from': '2014-05-19 12:02:32+02',
                            'from_included': True,
                            'notetekst': 'Nothing to see here!',
                            'to': 'infinity',
                            'to_included': False,
                        },
                    },
                ],
            },
        }

        self.assertQueryResponse(
            '/aktivitet/aktivitet',
            expected,
            uuid=objid,
        )

    def test_deleting_nothing(self):
        msg = (
            'No Aktivitet with ID 00000000-0000-0000-0000-000000000000 found.'
        )

        self.assertRequestResponse(
            '/aktivitet/aktivitet'
            '/00000000-0000-0000-0000-000000000000',
            {
                'message': msg,
            },
            method='DELETE',
            status_code=404,
        )

    def test_deleting_something(self):
        objid = self.load_fixture('/aktivitet/aktivitet',
                                  'aktivitet_opret.json')

        r = self.client.delete(
            '/aktivitet/aktivitet/' + objid,
        )

        self.assertEqual(r.status_code, 202)
        self.assertEqual(r.status, '202 ACCEPTED')
        self.assertEqual(r.json, {'uuid': objid})

        # once more for prince canut!
        self.assertRequestResponse(
            '/aktivitet/aktivitet/' + objid,
            {
                'uuid': objid,
            },
            status_code=202,
            method='DELETE',
        )
