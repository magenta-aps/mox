CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

CREATE TYPE LivscyklusKode AS ENUM (
  'Opstaaet',
  'Importeret',
  'Passiveret',
  'Slettet',
  'Rettet'
);

CREATE TYPE RegistreringsType AS (
  TimePeriod TSTZRANGE,
  LivscyklusKode LivscyklusKode,
  BrugerRef UUID
);

CREATE TYPE AktoerTypeKode AS ENUM (
  'Organisation',
  'OrganisationEnhed',
  'OrganisationFunktion',
  'Bruger',
  'ItSystem',
  'Interessefaellesskab'
);

CREATE TYPE Virkning AS (
  TimePeriod TSTZRANGE,
  AktoerRef UUID,
  AktoerTypeKode AktoerTypeKode,
  NoteTekst TEXT
);

CREATE TYPE AttributFeltType AS (
  Name TEXT,
  Value TEXT
);

CREATE TYPE AttributType AS (
  AttributFelter AttributFeltType[],
  Virkning Virkning
);

CREATE TYPE AttributterType AS (
  Name TEXT,
  Attributter AttributType[]
);

CREATE TYPE TilstandType AS (
  Virkning Virkning,
  Status TEXT
);

CREATE TYPE TilstandeType AS (
  Name TEXT,
  Tilstande TilstandType[]
);


CREATE TYPE RelationType AS (
  Virkning Virkning,
  ReferenceIDer UUID[]
);

CREATE TYPE RelationerType AS (
  Name TEXT,
  Relationer RelationType[]
);


-- Just returns the 'TimePeriod' field of the type passed in.
-- Used to work around limitations of PostgreSQL's exclusion constraints.
CREATE OR REPLACE FUNCTION composite_type_to_time_range(ANYELEMENT) RETURNS
  TSTZRANGE AS 'SELECT $1.TimePeriod' LANGUAGE sql STRICT IMMUTABLE;

-- Used to make GiST indexes on UUID type
-- Treats UUID as TEXT
CREATE OR REPLACE FUNCTION uuid_to_text(UUID) RETURNS TEXT AS 'SELECT $1::TEXT' LANGUAGE sql IMMUTABLE;

-- Shorthand for accessing Virkning time period for
-- Attribut/Tilstand/Relation tables
CREATE OR REPLACE FUNCTION period(ANYELEMENT) RETURNS TSTZRANGE AS 'SELECT ($1.Virkning).TimePeriod' LANGUAGE sql IMMUTABLE;
