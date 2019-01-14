# Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
# Contact: info@magenta.dk.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


from copy import deepcopy

# This specifies the database structure
DATABASE_STRUCTURE = {

    "facet": {
        "attributter": {
            "egenskaber": [
                "brugervendtnoegle", "beskrivelse", "opbygning", "ophavsret",
                "plan", "supplement", "retskilde", "integrationsdata",
            ],
        },
        "attributter_metadata": {
            'egenskaber': {
                'brugervendtnoegle': {'mandatory': True}
            }
        },
        "tilstande": {
            "publiceret": ["Publiceret", "IkkePubliceret"]
        },
        "relationer_nul_til_en": ["ansvarlig", "ejer", "facettilhoerer"],
        "relationer_nul_til_mange": ["redaktoerer"]
    },

    "klassifikation": {
        "attributter": {
            "egenskaber": [
                "brugervendtnoegle", "beskrivelse", "kaldenavn",
                "ophavsret",
            ],
        },
        "attributter_metadata": {
            'egenskaber': {
                'brugervendtnoegle': {'mandatory': True}
            }
        },
        "tilstande": {
            "publiceret": ["Publiceret", "IkkePubliceret"]

        },
        "relationer_nul_til_en": ["ansvarlig", "ejer"],
        "relationer_nul_til_mange": []
    },
    # Please notice, that the db templating code for klasse, is changed by
    # patches that are applied to handle the special case of 'soegeord' in the
    # 'egenskaber'-attribute.
    "klasse": {
        "attributter": {
            "egenskaber": [
                "brugervendtnoegle", "beskrivelse", "eksempel", "omfang",
                "titel", "retskilde", "aendringsnotat"],
        },
        "attributter_metadata": {
            'egenskaber': {
                'brugervendtnoegle': {'mandatory': True},
                'titel': {'mandatory': True},
            }
        },
        "tilstande": {
            "publiceret": ["Publiceret", "IkkePubliceret"]
        },
        "relationer_nul_til_en": [
            "ejer", "ansvarlig", "overordnetklasse", "facet"
        ],
        "relationer_nul_til_mange": [
            "redaktoerer", "sideordnede", "mapninger", "tilfoejelser",
            "erstatter", "lovligekombinationer"
        ]
    },

    "bruger": {
        "attributter": {
            "egenskaber": [
                "brugervendtnoegle", "brugernavn", "brugertype"
            ],
        },
        "attributter_metadata": {
            'egenskaber': {
                'brugervendtnoegle': {'mandatory': True}
            }
        },
        "tilstande": {
            "gyldighed": ["Aktiv", "Inaktiv"]
        },
        "relationer_nul_til_en": ["tilhoerer"],
        "relationer_nul_til_mange": [
            "adresser", "brugertyper", "opgaver", "tilknyttedeenheder",
            "tilknyttedefunktioner", "tilknyttedeinteressefaellesskaber",
            "tilknyttedeorganisationer", "tilknyttedepersoner",
            "tilknyttedeitsystemer"
        ]
    },

    "interessefaellesskab": {
        "attributter": {
            "egenskaber": [
                "brugervendtnoegle", "interessefaellesskabsnavn",
                "interessefaellesskabstype"
            ],
        },
        "attributter_metadata": {
            'egenskaber': {
                'brugervendtnoegle': {'mandatory': True}
            }
        },
        "tilstande": {
            "gyldighed": ["Aktiv", "Inaktiv"]
        },
        "relationer_nul_til_en": [
            "branche", "interessefaellesskabstype", "overordnet", "tilhoerer"
        ],
        "relationer_nul_til_mange": [
            "adresser", "opgaver", "tilknyttedebrugere", "tilknyttedeenheder",
            "tilknyttedefunktioner", "tilknyttedeinteressefaellesskaber",
            "tilknyttedeorganisationer", "tilknyttedepersoner",
            "tilknyttedeitsystemer"
        ]
    },

    "itsystem": {
        "attributter": {
            "egenskaber": [
                "brugervendtnoegle", "itsystemnavn", "itsystemtype",
                "konfigurationreference"],
        },
        "attributter_metadata": {
            'egenskaber': {
                'brugervendtnoegle': {'mandatory': True},
                'konfigurationreference': {'type': 'text[]'}
            }
        },
        "tilstande": {
            "gyldighed": ["Aktiv", "Inaktiv"]
        },
        "relationer_nul_til_en": [
            "tilhoerer"
        ],
        "relationer_nul_til_mange": [
            "tilknyttedeorganisationer", "tilknyttedeenheder",
            "tilknyttedefunktioner", "tilknyttedebrugere",
            "tilknyttedeinteressefaellesskaber", "tilknyttedeitsystemer",
            "tilknyttedepersoner", "systemtyper", "opgaver", "adresser"
        ]
    },

    "organisation": {
        "attributter": {
            "egenskaber": ["brugervendtnoegle", "organisationsnavn"],
        },
        "attributter_metadata": {
            'egenskaber': {
                'brugervendtnoegle': {'mandatory': True}
            }
        },
        "tilstande": {
            "gyldighed": ["Aktiv", "Inaktiv"]
        },
        "relationer_nul_til_en": [
            "branche", "myndighed", "myndighedstype", "overordnet",
            "produktionsenhed", "skatteenhed", "tilhoerer", "virksomhed",
            "virksomhedstype"
        ],
        "relationer_nul_til_mange": [
            "adresser", "ansatte", "opgaver", "tilknyttedebrugere",
            "tilknyttedeenheder", "tilknyttedefunktioner",
            "tilknyttedeinteressefaellesskaber", "tilknyttedeorganisationer",
            "tilknyttedepersoner", "tilknyttedeitsystemer"]
    },

    "organisationenhed": {
        "attributter": {
            "egenskaber": ["brugervendtnoegle", "enhedsnavn"],
        },
        "attributter_metadata": {
            'egenskaber': {
                'brugervendtnoegle': {'mandatory': True}
            }
        },
        "tilstande": {
            "gyldighed": ["Aktiv", "Inaktiv"]
        },
        "relationer_nul_til_en": [
            "branche", "enhedstype", "overordnet", "produktionsenhed",
            "skatteenhed", "tilhoerer"
        ],
        "relationer_nul_til_mange": [
            "adresser", "ansatte", "opgaver", "tilknyttedebrugere",
            "tilknyttedeenheder", "tilknyttedefunktioner",
            "tilknyttedeinteressefaellesskaber", "tilknyttedeorganisationer",
            "tilknyttedepersoner", "tilknyttedeitsystemer"
        ]

    },

    "organisationfunktion": {
        "attributter": {
            "egenskaber": ["brugervendtnoegle", "funktionsnavn"],
        },
        "attributter_metadata": {
            'egenskaber': {
                'brugervendtnoegle': {'mandatory': True}
            }
        },
        "tilstande": {
            "gyldighed": ["Aktiv", "Inaktiv"]
        },
        "relationer_nul_til_en": ["organisatoriskfunktionstype"],
        "relationer_nul_til_mange": [
            "adresser", "opgaver", "tilknyttedebrugere", "tilknyttedeenheder",
            "tilknyttedeorganisationer", "tilknyttedeitsystemer",
            "tilknyttedeinteressefaellesskaber", "tilknyttedepersoner"
        ]
    },

    "sag": {
        "attributter": {
            "egenskaber": ["brugervendtnoegle", "afleveret", "beskrivelse",
                           "hjemmel", "kassationskode",
                           "offentlighedundtaget", "principiel", "sagsnummer",
                           "titel"],
        },
        "attributter_metadata": {
            'egenskaber': {
                'afleveret': {'type': 'boolean'},
                'beskrivelse': {'mandatory': True},
                'brugervendtnoegle': {'mandatory': True},
                'kassationskode': {'mandatory': True},
                'offentlighedundtaget': {'type': 'offentlighedundtagettype'},
                'principiel': {'type': 'boolean'},
                'sagsnummer': {'mandatory': True},
                'titel': {'mandatory': True},
            }
        },
        "tilstande": {
            "fremdrift": ["Opstaaet", "Oplyst", "Afgjort", "Bestilt",
                          "Udfoert", "Afsluttet"]
        },
        "relationer_nul_til_en": [
            "behandlingarkiv", "afleveringsarkiv",
            "primaerklasse", "opgaveklasse", "handlingsklasse", "kontoklasse",
            "sikkerhedsklasse", "foelsomhedsklasse",
            "indsatsklasse", "ydelsesklasse", "ejer",
            "ansvarlig", "primaerbehandler",
            "udlaanttil", "primaerpart",
            "ydelsesmodtager", "oversag",
            "praecedens", "afgiftsobjekt",
            "ejendomsskat"
        ],
        "relationer_nul_til_mange": [
            "andetarkiv", "andrebehandlere", "sekundaerpart", "andresager",
            "byggeri", "fredning", "journalpost"
        ],
        'relationer_metadata': {
            '*': {
                'indeks': {'type': 'int'}
            },
            'journalpost': {
                'journalpostkode': {
                    'enum': ['journalnotat', 'vedlagtdokument'],
                    'mandatory': True,
                },
                'journalnotat': {'type': 'journalnotat'},
                'journaldokument': {'type': 'journaldokument'},
            },
        }
    },

    "dokument": {
        "attributter": {
            "egenskaber": ["brugervendtnoegle", "beskrivelse", "brevdato",
                           "kassationskode", "major", "minor",
                           "offentlighedundtaget", "titel", "dokumenttype"],
        },
        "attributter_metadata": {
            'egenskaber': {
                'beskrivelse': {'mandatory': True},
                'brevdato': {'mandatory': True, 'type': 'date'},
                'brugervendtnoegle': {'mandatory': True},
                'dokumenttype': {'mandatory': True},
                'major': {'type': 'int'},
                'minor': {'type': 'int'},
                'offentlighedundtaget': {'type': 'offentlighedundtagettype'},
                'titel': {'mandatory': True},
            }
        },
        "tilstande": {
            "fremdrift": ["Modtaget", "Fordelt", "Underudarbejdelse",
                          "Underreview", "Publiceret", "Endeligt",
                          "Afleveret"]
        },
        "relationer_nul_til_en": ["nyrevision", "primaerklasse", "ejer",
                                  "ansvarlig", "primaerbehandler",
                                  "fordelttil"],
        "relationer_nul_til_mange": ["arkiver", "besvarelser",
                                     "udgangspunkter", "kommentarer", "bilag",
                                     "andredokumenter", "andreklasser",
                                     "andrebehandlere", "parter",
                                     "kopiparter", "tilknyttedesager"]
    },

    "tilstand": {
        "attributter": {
            "egenskaber": [
                "brugervendtnoegle", "beskrivelse"],
        },
        "attributter_metadata": {
            'egenskaber': {
                'brugervendtnoegle': {'mandatory': True}
            }
        },
        "tilstande": [
            ("status", ["Inaktiv", "Aktiv"]),
            ("publiceret", ["Publiceret", "IkkePubliceret", "Normal"]),
        ],
        "relationer_nul_til_en": ["tilstandsobjekt", "tilstandstype"],
        "relationer_nul_til_mange": [
            "tilstandsvaerdi", "begrundelse", "tilstandskvalitet",
            "tilstandsvurdering", "tilstandsaktoer", "tilstandsudstyr",
            "samtykke", "tilstandsdokument"
        ],
        'relationer_metadata': {
            '*': {
                'indeks': {'type': 'int'}
            },
            'tilstandsvaerdi': {
                'tilstandsvaerdiattr': {'type': 'vaerdirelationattr'},
            }
        }
    },

    "aktivitet": {
        "attributter": {
            "egenskaber": [
                "brugervendtnoegle", "aktivitetnavn", "beskrivelse",
                "starttidspunkt", "sluttidspunkt", "tidsforbrug", "formaal"
            ],
        },
        "attributter_metadata": {
            'egenskaber': {
                'brugervendtnoegle': {'mandatory': True},
                'starttidspunkt': {'type': 'timestamptz'},
                'sluttidspunkt': {'type': 'timestamptz'},
                'tidsforbrug': {'type': 'interval(0)'}
            }
        },
        "tilstande": [
            ("status", ["Inaktiv", "Aktiv", "Aflyst"]),
            ("publiceret", ["Publiceret", "IkkePubliceret", "Normal"]),
        ],
        "relationer_nul_til_en": ["aktivitetstype", "emne", "foelsomhedklasse",
                                  "ansvarligklasse", "rekvirentklasse",
                                  "ansvarlig", "tilhoerer"],
        "relationer_nul_til_mange": [
            "udfoererklasse", "deltagerklasse", "objektklasse",
            "resultatklasse", "grundlagklasse", "facilitetklasse", "adresse",
            "geoobjekt", "position", "facilitet", "lokale",
            "aktivitetdokument", "aktivitetgrundlag", "aktivitetresultat",
            "udfoerer", "deltager"
        ],
        'relationer_metadata': {
            '*': {
                'indeks': {'type': 'int'},
                'aktoerattr': {'type': 'aktoerattr'}
            },
        }
    },

    "indsats": {
        "attributter": {
            "egenskaber": [
                "brugervendtnoegle", "beskrivelse", "starttidspunkt",
                "sluttidspunkt"
            ],
        },
        "attributter_metadata": {
            'egenskaber': {
                'brugervendtnoegle': {'mandatory': True},
                'starttidspunkt': {'type': 'timestamptz'},
                'sluttidspunkt': {'type': 'timestamptz'},
            }
        },
        "tilstande": [
            ("publiceret", ["Publiceret", "IkkePubliceret", "Normal"]),
            ("fremdrift", [
                "Uoplyst", "Visiteret", "Disponeret", "Leveret", "Vurderet"
            ]),
        ],
        "relationer_nul_til_en": ["indsatsmodtager", "indsatstype"],
        "relationer_nul_til_mange": [
            "indsatskvalitet", "indsatsaktoer", "samtykke", "indsatssag",
            "indsatsdokument"
        ],
        'relationer_metadata': {
            '*': {
                'indeks': {'type': 'int'}
            },
        }
    },

    "loghaendelse": {
        "attributter": {
            "egenskaber": ["service", "klasse", "tidspunkt", "operation",
                           "objekttype", "returkode", "returtekst", "note"],
        },
        "tilstande": {
            "gyldighed": ["Rettet", "Ikke rettet"]
        },
        "relationer_nul_til_en": ["objekt", "bruger", "brugerrolle"],
        "relationer_nul_til_mange": [],
    }
}

REAL_DB_STRUCTURE = deepcopy(DATABASE_STRUCTURE)
REAL_DB_STRUCTURE["klasse"]["attributter"]["egenskaber"].append("soegeord")
REAL_DB_STRUCTURE['klasse']['attributter_metadata']['egenskaber'][
    'soegeord'] = {'type': 'soegeord'}

DB_TEMPLATE_EXTRA_OPTIONS = {
    "dokument": {
        "as_search.jinja.sql": {
            "include_mixin": "as_search_dokument_mixin.jinja.sql"
        }
    }
}

if __name__ == "__main__":
    export_structure = "\n".join(sorted(REAL_DB_STRUCTURE))
    print(export_structure)
