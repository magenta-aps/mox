-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py aktivitet dbtyper-specific.jinja.sql
*/

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

CREATE TYPE AktivitetStatusTils AS ENUM ('Inaktiv','Aktiv','Aflyst',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE AktivitetStatusTilsType AS (
    virkning Virkning,
    status AktivitetStatusTils
)
;
CREATE TYPE AktivitetPubliceretTils AS ENUM ('Publiceret','IkkePubliceret','Normal',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE AktivitetPubliceretTilsType AS (
    virkning Virkning,
    publiceret AktivitetPubliceretTils
)
;

CREATE TYPE AktivitetEgenskaberAttrType AS (
brugervendtnoegle text,
aktivitetnavn text,
beskrivelse text,
starttidspunkt ClearableTimestamptz,
sluttidspunkt ClearableTimestamptz,
tidsforbrug ClearableInterval,
formaal text,
 virkning Virkning
);


CREATE TYPE AktivitetRelationKode AS ENUM  ('aktivitetstype','emne','foelsomhedklasse','ansvarligklasse','rekvirentklasse','ansvarlig','tilhoerer','udfoererklasse','deltagerklasse','objektklasse','resultatklasse','grundlagklasse','facilitetklasse','adresse','geoobjekt','position','facilitet','lokale','aktivitetdokument','aktivitetgrundlag','aktivitetresultat','udfoerer','deltager');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_aktivitet_relation_kode_to_txt is invoked.

CREATE TYPE AktivitetAktoerAttrObligatoriskKode AS ENUM ('noedvendig','valgfri');

CREATE TYPE AktivitetAktoerAttrAccepteretKode AS ENUM ('accepteret','foreloebigt','afslaaet');

CREATE TYPE  AktivitetAktoerAttr AS (
  obligatorisk AktivitetAktoerAttrObligatoriskKode,
  accepteret AktivitetAktoerAttrAccepteretKode,
  repraesentation_uuid uuid,
  repraesentation_urn text 
);


CREATE TYPE AktivitetRelationType AS (
  relType AktivitetRelationKode,
  virkning Virkning,
  uuid uuid,
  urn  text,
  objektType text,
  indeks int,
  aktoerAttr AktivitetAktoerAttr
)
;

CREATE TYPE AktivitetRegistreringType AS
(
registrering RegistreringBase,
tilsStatus AktivitetStatusTilsType[],
tilsPubliceret AktivitetPubliceretTilsType[],
attrEgenskaber AktivitetEgenskaberAttrType[],
relationer AktivitetRelationType[]
);

CREATE TYPE AktivitetType AS
(
  id uuid,
  registrering AktivitetRegistreringType[]
);  

 CREATE Type _AktivitetRelationMaxIndex AS
 (
   relType AktivitetRelationKode,
   indeks int
 );

--we'll add two small functions here, that will help with placing CHECK CONSTRAINT on the composite type AktivitetAktoerAttr in the db-table.
CREATE OR REPLACE FUNCTION _aktivitet_aktoer_attr_repr_uuid_to_text(AktivitetAktoerAttr) RETURNS TEXT AS 'SELECT $1.repraesentation_uuid::TEXT' LANGUAGE sql IMMUTABLE;
CREATE OR REPLACE FUNCTION _aktivitet_aktoer_attr_repr_urn_to_text(AktivitetAktoerAttr) RETURNS TEXT AS 'SELECT NULLIF($1.repraesentation_urn::TEXT,'''') ' LANGUAGE sql IMMUTABLE;
