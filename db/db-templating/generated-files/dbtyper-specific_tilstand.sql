-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py tilstand dbtyper-specific.jinja.sql
*/

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

CREATE TYPE TilstandStatusTils AS ENUM ('Inaktiv','Aktiv',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE TilstandStatusTilsType AS (
    virkning Virkning,
    status TilstandStatusTils
)
;
CREATE TYPE TilstandPubliceretTils AS ENUM ('Publiceret','IkkePubliceret','Normal',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE TilstandPubliceretTilsType AS (
    virkning Virkning,
    publiceret TilstandPubliceretTils
)
;

CREATE TYPE TilstandEgenskaberAttrType AS (
brugervendtnoegle text,
beskrivelse text,
 virkning Virkning
);


CREATE TYPE TilstandVaerdiRelationAttrType AS (
  forventet boolean,
  nominelVaerdi text
);

CREATE TYPE TilstandRelationKode AS ENUM  ('tilstandsobjekt','tilstandstype','tilstandsvaerdi','begrundelse','tilstandskvalitet','tilstandsvurdering','tilstandsaktoer','tilstandsudstyr','samtykke','tilstandsdokument');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_tilstand_relation_kode_to_txt is invoked.

CREATE TYPE TilstandRelationType AS (
  relType TilstandRelationKode,
  virkning Virkning,
  uuid uuid,
  urn  text,
  objektType text,
  indeks int,
  tilstandsVaerdiAttr TilstandVaerdiRelationAttrType
)
;

CREATE TYPE TilstandRegistreringType AS
(
registrering RegistreringBase,
tilsStatus TilstandStatusTilsType[],
tilsPubliceret TilstandPubliceretTilsType[],
attrEgenskaber TilstandEgenskaberAttrType[],
relationer TilstandRelationType[]
);

CREATE TYPE TilstandType AS
(
  id uuid,
  registrering TilstandRegistreringType[]
);  

 CREATE Type _TilstandRelationMaxIndex AS
 (
   relType TilstandRelationKode,
   indeks int
 );



