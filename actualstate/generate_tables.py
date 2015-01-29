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
  Registrering Registrering,
  -- Exclude overlapping Registrering time periods for the same 'actor' type.
  EXCLUDE USING gist (uuid_to_text(${table}ID) WITH =,
    composite_type_to_time_range(Registrering) WITH &&)
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
  -- Exclude overlapping Virkning time periods within the same registrering
  EXCLUDE USING gist (${table}RegistreringID WITH =,
    composite_type_to_time_range(Virkning) WITH &&),
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
  Status ${table}GyldighedStatus,
  -- Exclude overlapping Virkning time periods within the same registrering
  EXCLUDE USING gist (${table}RegistreringID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
);
""")


relation_template = Template("""
CREATE TABLE ${table}${relation}Relation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  ${table}RegistreringID INTEGER REFERENCES ${table}Registrering(ID),
  Relation UUID,
  Virkning Virkning,
  -- Exclude overlapping Virkning time periods within the same registrering
  -- and same relation UUID. We assume here that, for example, a user cannot
  -- have multiple entries of the same address during overlapping
  -- application time periods
  EXCLUDE USING gist (uuid_to_text(Relation) WITH =,
    ${table}RegistreringID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
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
