
BASE_URL = ''

DATABASE = 'mox'
DB_USER = 'mox'
DB_PASSWORD = 'mox'

DATABASE_STRUCTURE = {

    "Facet": {
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

    "Klassifikation": {
         "attributter": { 
                    "egenskaber" : [
                        "brugervendtnoegle", "beskrivelse", "kaldenavn", "ophavsret",
                    ]
                },
                "tilstande" : {
                    "publiceret": ["Publiceret", "IkkePubliceret"]
                },
                "relationer_nul_til_en" : ["ansvarlig","ejer"],
                "relationer_nul_til_mange" : []
    }
}
