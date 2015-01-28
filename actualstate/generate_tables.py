#!/usr/bin/env python

from string import Template

tables = {
    'Bruger': {
        'properties':"""
            Brugernavn TEXT,
            Brugertype TEXT""",

        'relations': ['Adresser', 'Brugertyper', 'Opgaver', 'Tilhoerer',
                      'TilknyttedeEnheder', 'TilknyttedeFunktioner',
                      'TilknyttedeInteressefaellesskab',
                      'TilknyttedeOrganisationer', 'TilknyttedePersoner',
                      'TilknyttedeItSystemer'],
    },
    'Organisation': {
        'properties':"""
            Organisationsnavn TEXT""",

        'relations': ['Adresser', 'Ansatte', 'Branche',
                      'Myndighed', 'Myndighedstype', 'Opgaver', 'Overordnet' 'Produktionsenhed', 'Skatteenhed',
                      'Tilhoerer', 'TilknyttedeBruger'
                      'TilknyttedeEnheder', 'TilknyttedeFunktioner',
                      'TilknyttedeInteressefaellesskab',
                      'TilknyttedeOrganisationer', 'TilknyttedePersoner',
                      'TilknyttedeItSystemer',
                      'Virksomhed', 'Virksomhedstype'],
        }
}

template = Template("""
CREATE TABLE ${table} (
  ID UUID NOT NULL PRIMARY KEY
);

CREATE TABLE ${table}Registrering  (
  ID BIGSERIAL PRIMARY KEY,
  ${table}ID UUID REFERENCES ${table}(ID),
  Registrering Registrering
);

CREATE TYPE ${table}EgenskaberType AS (
  Virkning Virkning,
  BrugervendtNoegle TEXT,
  ${properties}
);

CREATE TABLE ${table}Egenskaber (
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  ${table}RegistreringID INTEGER REFERENCES ${table}Registrering(ID),
  Virkning Virkning,
  BrugervendtNoegle TEXT,
  ${properties}
);

CREATE TYPE ${table}GyldighedStatus AS ENUM (
  'Aktiv',
  'Inaktiv'
);

CREATE TYPE ${table}TilstandType AS (
  Virkning Virkning,
  Status ${table}GyldighedStatus
);

CREATE TABLE ${table}Tilstand(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  ${table}RegistreringID INTEGER REFERENCES ${table}Registrering(ID),
  Virkning Virkning,
  Status ${table}GyldighedStatus
);
""")


relation_template = Template("""
CREATE TABLE ${table}${relation}Relation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  ${table}RegistreringID INTEGER REFERENCES ${table}Registrering(ID),
  Relation UUID,
  Virkning Virkning
);
""")

for table, obj in tables.iteritems():
    print template.substitute({
        'table': table,
        'properties': obj['properties'],
    })

    # Each relation for each type gets its own table
    for relation in obj['relations']:
        print relation_template.substitute({
            'table': table,
            'relation': relation
        })
