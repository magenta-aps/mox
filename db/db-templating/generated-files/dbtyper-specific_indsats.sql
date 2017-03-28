-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py indsats dbtyper-specific.jinja.sql
*/

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

CREATE TYPE IndsatsPubliceretTils AS ENUM ('Publiceret','IkkePubliceret','Normal',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE IndsatsPubliceretTilsType AS (
    virkning Virkning,
    publiceret IndsatsPubliceretTils
)
;
CREATE TYPE IndsatsFremdriftTils AS ENUM ('Uoplyst','Visiteret','Disponeret','Leveret','Vurderet',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE IndsatsFremdriftTilsType AS (
    virkning Virkning,
    fremdrift IndsatsFremdriftTils
)
;

CREATE TYPE IndsatsEgenskaberAttrType AS (
brugervendtnoegle text,
beskrivelse text,
starttidspunkt ClearableTimestamptz,
sluttidspunkt ClearableTimestamptz,
 virkning Virkning
);


CREATE TYPE IndsatsRelationKode AS ENUM  ('indsatsmodtager','indsatstype','indsatskvalitet','indsatsaktoer','samtykke','indsatssag','indsatsdokument');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_indsats_relation_kode_to_txt is invoked.

CREATE TYPE IndsatsRelationType AS (
  relType IndsatsRelationKode,
  virkning Virkning,
  uuid uuid,
  urn  text,
  objektType text,
indeks int 
)
;

CREATE TYPE IndsatsRegistreringType AS
(
registrering RegistreringBase,
tilsPubliceret IndsatsPubliceretTilsType[],
tilsFremdrift IndsatsFremdriftTilsType[],
attrEgenskaber IndsatsEgenskaberAttrType[],
relationer IndsatsRelationType[]
);

CREATE TYPE IndsatsType AS
(
  id uuid,
  registrering IndsatsRegistreringType[]
);  

 CREATE Type _IndsatsRelationMaxIndex AS
 (
   relType IndsatsRelationKode,
   indeks int
 );

