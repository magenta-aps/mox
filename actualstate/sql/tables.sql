DROP TYPE IF EXISTS Registrering, AktoerTypeKode, Virkning CASCADE;

CREATE TYPE LivscyklusKode AS ENUM (
  'Opstaaet',
  'Importeret',
  'Passiveret',
  'Slettet',
  'Rettet'
);

CREATE TYPE Registrering AS (
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


CREATE TABLE Organisation (
  ID UUID NOT NULL PRIMARY KEY
);

CREATE TABLE OrganisationRegistrering  (
  ID BIGSERIAL PRIMARY KEY,
  OrganisationID UUID REFERENCES Organisation(ID),
  Registrering Registrering
);

CREATE TABLE OrganisationEgenskaber (
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Virkning Virkning,
  BrugervendtNoegle TEXT,
  
            Organisationsnavn TEXT
);

CREATE TYPE OrganisationGyldighedStatus AS ENUM (
  'Aktiv',
  'Inaktiv'
);

CREATE TABLE OrganisationTilstand(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Virkning Virkning,
  Status OrganisationGyldighedStatus
);


CREATE TABLE OrganisationAdresserRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationAnsatteRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationBrancheRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationMyndighedRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationMyndighedstypeRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationOpgaverRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationOverordnetProduktionsenhedRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationSkatteenhedRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationTilhoererRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationTilknyttedeBrugerTilknyttedeEnhederRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationTilknyttedeFunktionerRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationTilknyttedeInteressefaellesskabRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationTilknyttedeOrganisationerRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationTilknyttedePersonerRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationTilknyttedeItSystemerRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationVirksomhedRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE OrganisationVirksomhedstypeRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  OrganisationRegistreringID INTEGER REFERENCES OrganisationRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE Bruger (
  ID UUID NOT NULL PRIMARY KEY
);

CREATE TABLE BrugerRegistrering  (
  ID BIGSERIAL PRIMARY KEY,
  BrugerID UUID REFERENCES Bruger(ID),
  Registrering Registrering
);

CREATE TABLE BrugerEgenskaber (
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  BrugerRegistreringID INTEGER REFERENCES BrugerRegistrering(ID),
  Virkning Virkning,
  BrugervendtNoegle TEXT,
  
            Brugernavn TEXT,
            Brugertype TEXT
);

CREATE TYPE BrugerGyldighedStatus AS ENUM (
  'Aktiv',
  'Inaktiv'
);

CREATE TABLE BrugerTilstand(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  BrugerRegistreringID INTEGER REFERENCES BrugerRegistrering(ID),
  Virkning Virkning,
  Status BrugerGyldighedStatus
);


CREATE TABLE BrugerAdresserRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  BrugerRegistreringID INTEGER REFERENCES BrugerRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE BrugerBrugertyperRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  BrugerRegistreringID INTEGER REFERENCES BrugerRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE BrugerOpgaverRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  BrugerRegistreringID INTEGER REFERENCES BrugerRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE BrugerTilhoererRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  BrugerRegistreringID INTEGER REFERENCES BrugerRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE BrugerTilknyttedeEnhederRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  BrugerRegistreringID INTEGER REFERENCES BrugerRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE BrugerTilknyttedeFunktionerRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  BrugerRegistreringID INTEGER REFERENCES BrugerRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE BrugerTilknyttedeInteressefaellesskabRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  BrugerRegistreringID INTEGER REFERENCES BrugerRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE BrugerTilknyttedeOrganisationerRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  BrugerRegistreringID INTEGER REFERENCES BrugerRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE BrugerTilknyttedePersonerRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  BrugerRegistreringID INTEGER REFERENCES BrugerRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);


CREATE TABLE BrugerTilknyttedeItSystemerRelation(
  ID BIGSERIAL NOT NULL PRIMARY KEY,
  BrugerRegistreringID INTEGER REFERENCES BrugerRegistrering(ID),
  Relation UUID,
  Virkning Virkning
);
