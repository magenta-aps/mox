# encoding: utf-8
#!/usr/bin/env python

from string import Template

tables = {
    'Bruger': {
        'atttributes': {
            'Egenskaber': ['BrugervendtNoegle', 'Brugernavn', 'Brugertype'],
        },
        'states': {'Gyldighed': ['Aktiv', 'Inaktiv'] },
        'relations': ['Adresser', 'Brugertyper', 'Opgaver', 'Tilhoerer',
                      'TilknyttedeEnheder', 'TilknyttedeFunktioner',
                      'TilknyttedeInteressefaellesskab',
                      'TilknyttedeOrganisationer', 'TilknyttedePersoner',
                      'TilknyttedeItSystemer'],
    },
    'Organisation': {
        'attributes': {
            'Egenskaber': ['BrugervendtNoegle', 'Organisationsnavn'],
        },
        'states': {'Gyldighed': ['Aktiv', 'Inaktiv'] },
        'relations': ['Adresser', 'Ansatte', 'Branche',
                      'Myndighed', 'Myndighedstype', 'Opgaver', 'Overordnet',
                      'Produktionsenhed', 'Skatteenhed',
                      'Tilhoerer', 'TilknyttedeBruger'
                      'TilknyttedeEnheder', 'TilknyttedeFunktioner',
                      'TilknyttedeInteressefaellesskab',
                      'TilknyttedeOrganisationer', 'TilknyttedePersoner',
                      'TilknyttedeItSystemer',
                      'Virksomhed', 'Virksomhedstype'],
        },
    'Interessefaellesskab': {
        'attributes': {
            'Egenskaber': ['BrugervendtNoegle', 'Interessefællesskabsnavn',
                           'Interessefællesskabstype'],
        },
        'states': {'Gyldighed': ['Aktiv', 'Inaktiv'] },
        'relations': ['Adresser', 'Branche', 'Interessefællesskabstype',
                      'Opgaver', 'Overordnet', 'Tilhører',
                      'TilknyttedeBrugere', 'TilknyttedeEnheder',
                      'TilknyttedeFunktioner',
                      'TilknyttedeInteressefællesskaber',
                      'TilknyttedeOrganisationer', 'TilknyttedePersoner',
                      'TilknyttedeItSystemer'],
    }
}

template = Template("""
CREATE TABLE ${table} (PRIMARY KEY (ID)) INHERITS (Objekt);

CREATE TABLE ${table}Registrering  (
  PRIMARY KEY (ID),
  FOREIGN KEY (ObjektID) REFERENCES ${table} (ID),
  -- Exclude overlapping Registrering time periods for the same 'actor' type.
  EXCLUDE USING gist (uuid_to_text(ObjektID) WITH =,
    TimePeriod WITH &&)
) INHERITS (Registrering);


CREATE TABLE ${table}Attributter (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES ${table}Registrering (ID),
) INHERITS (Attributter);


CREATE TABLE ${table}Attribut (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributterID) REFERENCES ${table}Attributter (ID),
    -- Exclude overlapping Virkning time periods within the same Attributter
    EXCLUDE USING gist (AttributterID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Attribut);


CREATE TABLE ${table}AttributFelt (
    PRIMARY KEY(ID),
    FOREIGN KEY (AttributID) REFERENCES ${table}Attribut (ID),
    UNIQUE (AttributID, Name)
) INHERITS (AttributFelt);


CREATE TABLE ${table}Tilstande (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES ${table}Registrering (ID)
) INHERTIS (Tilstande);


CREATE TABLE ${table}Tilstand (
    PRIMARY KEY(ID),
    FOREIGN KEY (TilstandeID) REFERENCES ${table}Tilstande (ID),
    -- Exclude overlapping Virkning time periods within the same Tilstand
    EXCLUDE USING gist (TilstandeID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Tilstand);


CREATE TABLE ${table}Relationer(
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES ${table}Registrering (ID)
) INHERITS (Relationer);
    

CREATE TABLE ${table}Relation(
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationerID) REFERENCES ${table}Relationer(ID),
    -- Exclude overlapping Virkning time periods within the same Relation
    EXCLUDE USING gist (RelationerID WITH =,
      composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Relation);


CREATE TABLE ${table}Reference (
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationID) REFERENCES ${table}Relation(ID),
    -- No duplicates within the same relation!
    UNIQUE (ReferenceID, RelationID)
) INHERITS (Reference);
""")

for table, obj in tables.iteritems():
    print template.substitute({
        'table': table,
        # TODO: Use attribute field names, status values etc. for constraints.
    })

