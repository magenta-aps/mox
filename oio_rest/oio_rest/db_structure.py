from copy import deepcopy

# This specifies the database structure
DATABASE_STRUCTURE = {

    "facet": {
        "attributter": {
            "egenskaber": [
                "brugervendtnoegle", "beskrivelse", "opbygning", "ophavsret",
                "plan", "supplement", "retskilde"
            ]
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
            ]
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
                "titel", "retskilde", "aendringsnotat"
            ]
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
            ]
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
            ]
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
                "konfigurationreference"]
        },
        "attributter_type_override": {
            "egenskaber": {
                "konfigurationreference": "text[]"
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
            "egenskaber": ["brugervendtnoegle", "organisationsnavn"]
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
            "egenskaber": ["brugervendtnoegle", "enhedsnavn"]
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
            "egenskaber": ["brugervendtnoegle", "funktionsnavn"]
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
                           "titel"]
        },
        "attributter_type_override": {
            "egenskaber": {
                "afleveret": "boolean",
                "principiel": "boolean",
                "offentlighedundtaget": "offentlighedundtagettype"
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
        ]

    },

    "dokument": {
        "attributter": {
            "egenskaber": ["brugervendtnoegle", "beskrivelse", "brevdato",
                           "kassationskode", "major", "minor",
                           "offentlighedundtaget", "titel", "dokumenttype"]
            },
        "attributter_type_override": {
            "egenskaber": {
                "brevdato": "date",
                "major": "int",
                "minor": "int",
                "offentlighedundtaget": "offentlighedundtagettype"
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
                "brugervendtnoegle", "beskrivelse"]
        },
        "tilstande": {
            "status": ["Inaktiv", "Aktiv"],
            "publiceret": ["Publiceret", "IkkePubliceret", "Normal"]
        },
        "relationer_nul_til_en": ["tilstandsobjekt", "tilstandstype"],
        "relationer_nul_til_mange": [
            "tilstandsvaerdi", "begrundelse", "tilstandskvalitet",
            "tilstandsvurdering", "tilstandsaktoer", "tilstandsudstyr",
            "samtykke", "tilstandsdokument"
            ]
        },
    "aktivitet": {
        "attributter": {
            "egenskaber": [
                "brugervendtnoegle", "aktivitetnavn", "beskrivelse",
                "starttidspunkt", "sluttidspunkt", "tidsforbrug", "formaal"
            ]
        },
        "attributter_type_override": {
            "egenskaber": {
                "starttidspunkt": "timestamptz",
                "sluttidspunkt": "timestamptz",
                "tidsforbrug": "interval(0)"
            }
        },
        "tilstande": {
            "status": ["Inaktiv", "Aktiv", "Aflyst"],
            "publiceret": ["Publiceret", "IkkePubliceret", "Normal"]
        },
        "relationer_nul_til_en": ["aktivitetstype", "emne", "foelsomhedklasse",
                                  "ansvarligklasse", "rekvirentklasse",
                                  "ansvarlig", "tilhoerer"],
        "relationer_nul_til_mange": [
            "udfoererklasse", "deltagerklasse", "objektklasse",
            "resultatklasse", "grundlagklasse", "facilitetklasse", "adresse",
            "geoobjekt", "position", "facilitet", "lokale",
            "aktivitetdokument", "aktivitetgrundlag", "aktivitetresultat",
            "udfoerer", "deltager"
        ]
    },
    "indsats": {
        "attributter": {
            "egenskaber": [
                "brugervendtnoegle", "beskrivelse", "starttidspunkt",
                "sluttidspunkt"
            ]
        },
        "attributter_type_override": {
            "egenskaber": {
                "starttidspunkt": "timestamptz",
                "sluttidspunkt": "timestamptz",
                }
        },
        "tilstande": {
            "fremdrift": [
                "Uoplyst", "Visiteret", "Disponeret", "Leveret", "Vurderet"
            ],
            "publiceret": ["Publiceret", "IkkePubliceret", "Normal"]
        },
        "relationer_nul_til_en": ["indsatsmodtager", "indsatstype"],
        "relationer_nul_til_mange": [
            "indsatskvalitet", "indsatsaktoer", "samtykke", "indsatssag",
            "indsatsdokument"
        ]
    },

    "loghaendelse": {
        "attributter": {
            "egenskaber": ["service", "klasse", "tidspunkt", "operation",
                           "objekttype", "returkode", "returtekst", "note"]
        },
        "tilstande": {
            "gyldighed": ["Rettet", "Ikke rettet"]
        },
        "relationer_nul_til_en": ["objekt", "bruger", "brugerrolle"],

        "relationer_nul_til_mange": []

    }
}

REAL_DB_STRUCTURE = deepcopy(DATABASE_STRUCTURE)
REAL_DB_STRUCTURE["klasse"]["attributter"]["egenskaber"].append("soegeord")
REAL_DB_STRUCTURE["klasse"]["attributter_type_override"] = {
    "egenskaber": {
        "soegeord": "soegeord"
    }
}
REAL_DB_STRUCTURE["sag"]["relationer_type_override"] = {
    "journalnotat": "journalnotat",
    "journaldokument": "journaldokument"
}

REAL_DB_STRUCTURE["aktivitet"]["relationer_type_override"] = {
    "aktoerattr": "aktoerattr"
}

REAL_DB_STRUCTURE["tilstand"]["relationer_type_override"] = {
    "tilstandsvaerdiattr": "vaerdirelationattr"
}

DB_TEMPLATE_EXTRA_OPTIONS = {
    "dokument": {
        "as_search.jinja.sql": {
            "include_mixin": "as_search_dokument_mixin.jinja.sql"
        }
    }
}
