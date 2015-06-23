from copy import deepcopy

BASE_URL = ''

DATABASE = 'mox'
DB_USER = 'mox'
DB_PASSWORD = 'mox'

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
            "egenskaber": ["brugervendtnoegle","afleveret","beskrivelse","hjemmel","kassationskode","offentlighedundtaget","principiel","sagsnummer","titel"]
        },
        "attributter_type_override": {
            "egenskaber": {
                "afleveret": "boolean",
                "principiel": "boolean",
                "offentlighedundtaget" : "offentlighedundtagettype"
            }
            },
        "tilstande": {
            "fremdrift": ["Opstaaet","Oplyst","Afgjort","Bestilt","Udfoert","Afsluttet"]
        },
        "relationer_nul_til_en": ["behandlingarkiv","afleveringsarkiv",
            "primaerklasse","opgaveklasse","handlingsklasse","kontoklasse","sikkerhedsklasse","foelsomhedsklasse","indsatsklasse","ydelsesklasse",
            "ejer","ansvarlig","primaerbehandler","udlaanttil",
            "primaerpart","ydelsesmodtager",
            "oversag","praecedens",
            "afgiftsobjekt","ejendomsskat"
        ],
        "relationer_nul_til_mange": [
            "andetarkiv","andrebehandlere","sekundaerpart","andresager","byggeri","fredning","journalpost"
        ]

    }

}


REAL_DB_STRUCTURE = deepcopy(DATABASE_STRUCTURE)
REAL_DB_STRUCTURE["klasse"]["attributter"]["egenskaber"].append("soegeord")
REAL_DB_STRUCTURE["klasse"]["attributter_type_override"] = {
    "egenskaber": {
        "soegeord": "soegeord"
    }
}

