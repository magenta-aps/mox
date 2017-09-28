import json
from unittest import TestCase

import pytest as pytest

from oio_rest import app as flaskapp


@pytest.mark.skip
class TestIntegration(TestCase):
    # PostgreSQL server is terminated here
    def setUp(self):
        flaskapp.app.testing = True
        self.app = flaskapp.app.test_client()
        flaskapp.setup_api()

    def test_(self):
        # Arrange
        # Act

        data = {
            "note": "Ny aktivitet",
            "attributter": {
                "aktivitetegenskaber": [
                    {
                        "brugervendtnoegle": "JOGGING",
                        "aktivitetnavn": "XYZ",
                        "beskrivelse": "Jogging",
                        "formaal": "Ja",
                        "starttidspunkt": "2014-05-19 12:02:32+00:00",
                        "sluttidspunkt": "2016-05-19 14:02:32+00:00",
                        "tidsforbrug": "2 hours",
                        "virkning": {
                            "from": "2014-05-19 12:02:32",
                            "to": "infinity",
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "aktoertypekode": "Bruger",
                            "notetekst": "Nothing to see here!"
                        }
                    }
                ]
            },
            "tilstande": {
                "aktivitetstatus": [{
                    "status": "Aktiv",
                    "virkning": {
                        "from": "2014-05-19 12:02:32",
                        "to": "infinity",
                        "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                        "aktoertypekode": "Bruger",
                        "notetekst": "Nothing to see here!"
                    }
                }
                ],
                "aktivitetpubliceret": [{
                    "publiceret": "Publiceret",
                    "virkning": {
                        "from": "2014-05-19 12:02:32",
                        "to": "infinity",
                        "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                        "aktoertypekode": "Bruger",
                        "notetekst": "Nothing to see here!"
                    }
                }
                ]
            },
            "relationer": {
                "ansvarlig": [
                    {
                        "aktoerattr": {
                            "accepteret": "foreloebigt",
                            "obligatorisk": "valgfri",
                            "repraesentation_uuid": "0e3ed41a-08f2-4967-8689-dce625f93029"
                        },
                        "uuid": "abcdeabd-c1b0-48c2-aef7-74fea841adae",
                        "virkning": {
                            "from": "2014-05-19 12:02:32",
                            "to": "infinity",
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "aktoertypekode": "Bruger",
                            "notetekst": "Nothing to see here!"

                        },
                        "objekttype": "Bruger"
                    }
                ],
                "deltager": [
                    {
                        "indeks": 2,
                        "aktoerattr": {
                            "accepteret": "foreloebigt",
                            "obligatorisk": "valgfri",
                            "repraesentation_uuid": "0e3ed41a-08f2-4967-8689-dce625f93029"
                        },
                        "uuid": "123deabd-c1b0-48c2-aef7-74fea841adae",
                        "virkning": {
                            "from": "2014-05-19 12:02:32",
                            "to": "infinity",
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "aktoertypekode": "Bruger",
                            "notetekst": "Nothing to see here!"

                        },
                        "objekttype": "Bruger"
                    },
                    {
                        "indeks": 1,
                        "aktoerattr": {
                            "accepteret": "foreloebigt",
                            "obligatorisk": "valgfri",
                            "repraesentation_uuid": "0123d41a-08f2-4967-8689-dce625f93029"
                        },
                        "uuid": "22345abd-c1b0-48c2-aef7-74fea841adae",
                        "virkning": {
                            "from": "2014-05-19 12:02:32",
                            "to": "infinity",
                            "aktoerref": "ddc99abd-c1b0-48c2-aef7-74fea841adae",
                            "aktoertypekode": "Bruger",
                            "notetekst": "Nothing to see here!"

                        },
                        "objekttype": "Bruger"
                    }
                ]
            }

        }

        result = self.app.post('/aktivitet/aktivitet',
                               data=json.dumps(data),
                               content_type='application/json')
        print(result.data)

        # Assert
