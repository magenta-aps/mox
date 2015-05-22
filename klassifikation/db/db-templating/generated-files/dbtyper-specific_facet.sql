-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py facet dbtyper-specific.jinja.sql
*/

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

CREATE TYPE FacetTilsPubliceret AS ENUM ('Publiceret','IkkePubliceret',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE FacetTilsPubliceretType AS (
    virkning Virkning,
    publiceret FacetTilsPubliceret
)
;

CREATE TYPE FacetAttrEgenskaberType AS (
brugervendtnoegle text,
beskrivelse text,
opbygning text,
ophavsret text,
plan text,
supplement text,
retskilde text,
 virkning Virkning
);


CREATE TYPE FacetRelationKode AS ENUM  ('ansvarlig','ejer','facettilhoerer','redaktoerer');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _actual_state_convert_facet_relation_kode_to_txt is invoked.

CREATE TYPE FacetRelationType AS (
  relType FacetRelationKode,
  virkning Virkning,
  relMaal uuid 
)
;

CREATE TYPE FacetRegistreringType AS
(
registrering RegistreringBase,
tilsPubliceret FacetTilsPubliceretType[],
attrEgenskaber FacetAttrEgenskaberType[],
relationer FacetRelationType[]
);

CREATE TYPE FacetType AS
(
  id uuid,
  registrering FacetRegistreringType[]
);  



