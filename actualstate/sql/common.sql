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

CREATE TYPE GyldighedsStatus AS ENUM (
  'Aktiv',
  'Inaktiv'
);

CREATE TYPE EgenskabsType AS (
  Name TEXT,
  Value TEXT
);

CREATE TYPE EgenskaberType AS (
  Properties EgenskabsType[],
  Virkning Virkning,
  BrugervendtNoegle TEXT
);

CREATE TYPE TilstandsType AS (
  Virkning Virkning,
  Status GyldighedsStatus
);

CREATE TYPE RelationsType AS (
  Virkning Virkning,
  Relation UUID
);

CREATE TYPE RelationsListeType AS (
  Name TEXT,
  Relations RelationsType[]
);


-- Just returns the 'TimePeriod' field of the type passed in.
-- Used to work around limitations of PostgreSQL's exclusion constraints.
CREATE OR REPLACE FUNCTION composite_type_to_time_range(ANYELEMENT) RETURNS
  TSTZRANGE AS 'SELECT $1.TimePeriod' LANGUAGE sql STRICT IMMUTABLE;

-- Used to make GiST indexes on UUID type
-- Treats UUID as TEXT
CREATE OR REPLACE FUNCTION uuid_to_text(UUID) RETURNS TEXT AS 'SELECT $1::TEXT' LANGUAGE sql IMMUTABLE;
