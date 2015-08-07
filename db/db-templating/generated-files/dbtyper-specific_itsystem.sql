-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py itsystem dbtyper-specific.jinja.sql
*/

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

CREATE TYPE ItsystemGyldighedTils AS ENUM ('Aktiv','Inaktiv',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE ItsystemGyldighedTilsType AS (
    virkning Virkning,
    gyldighed ItsystemGyldighedTils
)
;

CREATE TYPE ItsystemEgenskaberAttrType AS (
brugervendtnoegle text,
itsystemnavn text,
itsystemtype text,
konfigurationreference text[],
 virkning Virkning
);


CREATE TYPE ItsystemRelationKode AS ENUM  ('tilhoerer','tilknyttedeorganisationer','tilknyttedeenheder','tilknyttedefunktioner','tilknyttedebrugere','tilknyttedeinteressefaellesskaber','tilknyttedeitsystemer','tilknyttedepersoner','systemtyper','opgaver','adresser');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_itsystem_relation_kode_to_txt is invoked.

CREATE TYPE ItsystemRelationType AS (
  relType ItsystemRelationKode,
  virkning Virkning,
  relMaalUuid uuid,
  relMaalUrn  text,
  objektType text 
)
;

CREATE TYPE ItsystemRegistreringType AS
(
registrering RegistreringBase,
tilsGyldighed ItsystemGyldighedTilsType[],
attrEgenskaber ItsystemEgenskaberAttrType[],
relationer ItsystemRelationType[]
);

CREATE TYPE ItsystemType AS
(
  id uuid,
  registrering ItsystemRegistreringType[]
);  



