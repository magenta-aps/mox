import os
from copy import deepcopy

BASE_URL = ''

DATABASE = 'mox'
DB_USER = 'mox'
DB_PASSWORD = 'mox'

# This is where file uploads are stored. It must be readable and writable by
# the mox user, running the REST API server. This is used in the Dokument
# hierarchy.
FILE_UPLOAD_FOLDER = '/var/mox'

# The Endpoint specified in the AppliesTo element of the STS request
# This will be used to verify the Audience of the SAML Assertion
SAML_MOX_ENTITY_ID = 'https://${domain}'

# The entity ID of the IdP. This will be used to verify the token Issuer
SAML_IDP_ENTITY_ID = 'localhost'

# The URL on which to access the SAML IdP.
SAML_IDP_URL = ("https://${domain}:9443/services/wso2carbon-sts?wsdl")

# The public certificate file of the IdP, in PEM-format.
SAML_IDP_CERTIFICATE = "test_auth_data/idp-certificate.pem"

# Whether to enable SAML authentication
USE_SAML_AUTHENTICATION = True

# Whether authorization is enabled - if not, the restrictions module is not
# called.
DO_ENABLE_RESTRICTIONS = True

# The module which implements the authorization restrictions.
# Must be present in sys.path.
AUTH_RESTRICTION_MODULE = 'oio_rest.auth.wso_restrictions'
# The name of the function which retrieves the restrictions.
# Must be present in AUTH_RESTRICTION_MODULE and have the correct signature.
AUTH_RESTRICTION_FUNCTION = 'get_auth_restrictions'
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
#
DB_TEMPLATE_EXTRA_OPTIONS = {
    "dokument": {
        "as_search.jinja.sql": {
            "include_mixin": "as_search_dokument_mixin.jinja.sql"
        }
    }
}

MOX_BASE_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', '..')
)
