DROP TABLE IF EXISTS Objekt;
DROP TABLE IF EXISTS Registrering;
DROP TABLE IF EXISTS Egenskab;
DROP TABLE IF EXISTS Egenskaber;
DROP TABLE IF EXISTS Tilstand;
DROP TABLE IF EXISTS RelationsListe;
DROP TABLE IF EXISTS Relation;

CREATE TABLE Objekt (
  ID UUID NOT NULL PRIMARY KEY
);

CREATE TABLE Registrering  (
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  ObjektID UUID, -- Must reference Objekt for specific class
  TimePeriod TSTZRANGE,
  LivscyklusKode LivscyklusKode,
  BrugerRef UUID,
  Note TEXT
  -- TBD on subclass:
  -- Exclude overlapping Registrering time periods for the same 'actor' type.
);


CREATE TABLE Attribut (
    ID BIGSERIAL NOT NULL PRIMARY KEY,
    AttributterID BIGINT,  -- must reference Attributter for derived class
    Virkning Virkning
  -- TBD on subclass:
  -- Exclude overlapping Virkning time periods within the same registrering
  -- EXCLUDE USING gist (${table}RegistreringID WITH =,
  --  composite_type_to_time_range(Virkning) WITH &&)
);

CREATE TABLE AttributFelt (
    ID BIGSERIAL NOT NULL PRIMARY KEY,
    AttributID BIGINT, -- must reference property set (Egenskaber) for object
    Name TEXT NOT NULL,
    Value TEXT
);

CREATE TABLE Attributter (
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  RegistreringsID BIGINT, -- must reference registration for object and period
  Name TEXT NOT NULL

);

CREATE TABLE Tilstande (
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  RegistreringsID BIGINT, -- must reference registration for object and period
  Name TEXT NOT NULL
);

CREATE TABLE Tilstand(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  TilstandeID BIGINT, -- must reference Tilstande
  Virkning Virkning,
  Status TEXT
  -- TBD on subclass:
  -- Exclude overlapping Virkning time periods within the same registrering
  -- EXCLUDE USING gist (${table}RegistreringID WITH =,
  --  composite_type_to_time_range(Virkning) WITH &&)
);

CREATE TABLE Relationer(
    ID BIGSERIAL NOT NULL PRIMARY KEY,
    RegistreringsID BIGINT, -- must reference appropriate registration
    Name TEXT NOT NULL
);


CREATE TABLE Relation(
    ID BIGSERIAL NOT NULL PRIMARY KEY,
    RelationerID BIGINT, 
    Virkning Virkning
);

CREATE TABLE Reference(
    ID BIGSERIAL NOT NULL PRIMARY KEY, 
    RelationID BIGINT, -- References relation
    ReferenceID UUID
);
