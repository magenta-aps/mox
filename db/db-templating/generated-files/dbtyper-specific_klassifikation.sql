-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klassifikation dbtyper-specific.jinja.sql
*/

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

CREATE TYPE KlassifikationPubliceretTils AS ENUM ('Publiceret','IkkePubliceret',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE KlassifikationPubliceretTilsType AS (
    virkning Virkning,
    publiceret KlassifikationPubliceretTils
)
;



CREATE TYPE KlassifikationEgenskaberAttrType AS (
brugervendtnoegle text,
beskrivelse text,
kaldenavn text,
ophavsret text,

 virkning Virkning
);




CREATE TYPE KlassifikationRelationKode AS ENUM  ('ansvarlig','ejer');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_klassifikation_relation_kode_to_txt is invoked.



CREATE TYPE KlassifikationRelationType AS (
  relType KlassifikationRelationKode,
  virkning Virkning,
  uuid uuid,
  urn  text,
  objektType text
)
;



CREATE TYPE KlassifikationRegistreringType AS
(
registrering RegistreringBase,
tilsPubliceret KlassifikationPubliceretTilsType[],
attrEgenskaber KlassifikationEgenskaberAttrType[],
relationer KlassifikationRelationType[]
);

CREATE TYPE KlassifikationType AS
(
  id uuid,
  registrering KlassifikationRegistreringType[]
);  






