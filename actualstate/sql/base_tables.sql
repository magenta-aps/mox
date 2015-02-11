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
  BrugerRef UUID
  -- TBD on subclass:
  -- Exclude overlapping Registrering time periods for the same 'actor' type.
);


CREATE TABLE Egenskab (
    ID BIGSERIAL NOT NULL PRIMARY KEY,
    EgenskaberID BIGINT, -- must reference property set (Egenskaber) for object
    Name TEXT,
    Value TEXT
);

CREATE TABLE Egenskaber (
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  RegistreringsID BIGINT, -- must reference registration for object and period
  Virkning Virkning,
  BrugervendtNoegle TEXT
  -- TBD on subclass:
  -- Exclude overlapping Virkning time periods within the same registrering

);

CREATE TABLE Tilstand(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  RegistreringsID BIGINT, -- must reference registration
  Virkning Virkning,
  Status GyldighedsStatus
  -- TBD on subclass:
  -- Exclude overlapping Virkning time periods within the same registrering
  -- EXCLUDE USING gist (${table}RegistreringID WITH =,
  --  composite_type_to_time_range(Virkning) WITH &&)
);

CREATE VIEW TilstandUpdateView AS SELECT * FROM Tilstand;

CREATE TABLE RelationsListe(
    ID BIGSERIAL NOT NULL PRIMARY KEY,
    RegistreringsID BIGINT, -- must reference appropriate registration
    Name TEXT
);

CREATE TABLE Relation(
    ID BIGSERIAL NOT NULL PRIMARY KEY, 
    RelationsListeID BIGINT, -- References relationsliste
    Virkning Virkning,
    Relation UUID
);
