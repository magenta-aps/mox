-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py dokument dbtyper-specific.jinja.sql
*/

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

CREATE TYPE DokumentFremdriftTils AS ENUM ('Modtaget','Fordelt','Underudarbejdelse','Underreview','Publiceret','Endeligt','Afleveret',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE DokumentFremdriftTilsType AS (
    virkning Virkning,
    fremdrift DokumentFremdriftTils
)
;

CREATE TYPE DokumentEgenskaberAttrType AS (
brugervendtnoegle text,
beskrivelse text, 
brevdato date,
kassationskode text, 
major int, 
minor int, 
offentlighedundtaget offentlighedundtagettype,
titel text,
dokumenttype text,
 virkning Virkning
);


CREATE TYPE DokumentRelationKode AS ENUM  ('nyrevision','primaerklasse','ejer','ansvarlig','primaerbehandler','fordelttil','arkiver','besvarelser','udgangspunkter','kommentarer','bilag','andredokumenter','andreklasser','andrebehandlere','parter','kopiparter','tilknyttedesager');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_dokument_relation_kode_to_txt is invoked.

CREATE TYPE DokumentRelationType AS (
  relType DokumentRelationKode,
  virkning Virkning,
  relMaalUuid uuid,
  relMaalUrn  text,
  objektType text 
)
;

CREATE TYPE DokumentRegistreringType AS
(
registrering RegistreringBase,
tilsFremdrift DokumentFremdriftTilsType[],
attrEgenskaber DokumentEgenskaberAttrType[],
relationer DokumentRelationType[]
);

CREATE TYPE DokumentType AS
(
  id uuid,
  registrering DokumentRegistreringType[]
);  


CREATE TYPE DokumentdelRelationKode AS ENUM  ('underredigeringaf');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_dokumentdel_relation_kode_to_txt is invoked.

