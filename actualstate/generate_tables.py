# encoding: utf-8
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
                      'Myndighed', 'Myndighedstype', 'Opgaver', 'Overordnet',
                      'Produktionsenhed', 'Skatteenhed',
                      'Tilhoerer', 'TilknyttedeBruger'
                      'TilknyttedeEnheder', 'TilknyttedeFunktioner',
                      'TilknyttedeInteressefaellesskab',
                      'TilknyttedeOrganisationer', 'TilknyttedePersoner',
                      'TilknyttedeItSystemer',
                      'Virksomhed', 'Virksomhedstype'],
        },
    'Interessefællesskab': {
        'properties': """
            Interessefællesskabsnavn TEXT,
            Interessefællesskabstype TEXT""",
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


CREATE TABLE ${table}Egenskaber (
    PRIMARY KEY(ID),
    FOREIGN KEY (RegistreringsID) REFERENCES ${table}Registrering (ID),
    -- Exclude overlapping Virkning time periods within the same registrering
    EXCLUDE USING gist (RegistreringsID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Egenskaber);


CREATE TABLE ${table}Egenskab (
    PRIMARY KEY (ID),
    FOREIGN KEY (EgenskaberID) REFERENCES ${table}Egenskaber (ID)
) INHERITS (Egenskab);


CREATE TABLE ${table}Tilstand(
    PRIMARY KEY (ID),
    FOREIGN KEY (RegistreringsID) REFERENCES ${table}Registrering(ID),
  -- Exclude overlapping Virkning time periods within the same registrering
  EXCLUDE USING gist (RegistreringsID WITH =,
    composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Tilstand);

CREATE TABLE ${table}RelationsListe(
    PRIMARY KEY (ID),
    FOREIGN KEY (RegistreringsID) REFERENCES ${table}Registrering(ID)
) INHERITS (RelationsListe);

CREATE TABLE ${table}Relation(
    PRIMARY KEY (ID),
    FOREIGN KEY (RelationsListeID) REFERENCES ${table}RelationsListe(ID),
    -- have multiple entries of the same address during overlapping
    -- application time periods
    EXCLUDE USING gist (uuid_to_text(Relation) WITH =,
      RelationsListeID WITH =,
      composite_type_to_time_range(Virkning) WITH &&)
) INHERITS (Relation);
""")

for table, obj in tables.iteritems():
    print template.substitute({
        'table': table,
        'properties': obj['properties'],
    })

