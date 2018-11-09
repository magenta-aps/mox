-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py loghaendelse dbtyper-specific.jinja.sql
*/

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

CREATE TYPE LoghaendelseGyldighedTils AS ENUM ('Rettet','Ikke rettet',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE LoghaendelseGyldighedTilsType AS (
    virkning Virkning,
    gyldighed LoghaendelseGyldighedTils
)
;

CREATE TYPE LoghaendelseEgenskaberAttrType AS (
service text,
klasse text,
tidspunkt text,
operation text,
objekttype text,
returkode text,
returtekst text,
note text,
 virkning Virkning
);


CREATE TYPE LoghaendelseRelationKode AS ENUM  ('objekt','bruger','brugerrolle');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_loghaendelse_relation_kode_to_txt is invoked.

CREATE TYPE LoghaendelseRelationType AS (
  relType LoghaendelseRelationKode,
  virkning Virkning,
  uuid uuid,
  urn  text,
  objektType text 
)
;

CREATE TYPE LoghaendelseRegistreringType AS
(
registrering RegistreringBase,
tilsGyldighed LoghaendelseGyldighedTilsType[],
attrEgenskaber LoghaendelseEgenskaberAttrType[],
relationer LoghaendelseRelationType[]
);

CREATE TYPE LoghaendelseType AS
(
  id uuid,
  registrering LoghaendelseRegistreringType[]
);  



