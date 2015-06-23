-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py interessefaellesskab dbtyper-specific.jinja.sql
*/

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

CREATE TYPE InteressefaellesskabGyldighedTils AS ENUM ('Aktiv','Inaktiv',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE InteressefaellesskabGyldighedTilsType AS (
    virkning Virkning,
    gyldighed InteressefaellesskabGyldighedTils
)
;

CREATE TYPE InteressefaellesskabEgenskaberAttrType AS (
brugervendtnoegle text,
interessefaellesskabsnavn text,
interessefaellesskabstype text,
 virkning Virkning
);


CREATE TYPE InteressefaellesskabRelationKode AS ENUM  ('branche','interessefaellesskabstype','overordnet','tilhoerer','adresser','opgaver','tilknyttedebrugere','tilknyttedeenheder','tilknyttedefunktioner','tilknyttedeinteressefaellesskaber','tilknyttedeorganisationer','tilknyttedepersoner','tilknyttedeitsystemer');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_interessefaellesskab_relation_kode_to_txt is invoked.

CREATE TYPE InteressefaellesskabRelationType AS (
  relType InteressefaellesskabRelationKode,
  virkning Virkning,
  relMaalUuid uuid,
  relMaalUrn  text,
  objektType text 
)
;

CREATE TYPE InteressefaellesskabRegistreringType AS
(
registrering RegistreringBase,
tilsGyldighed InteressefaellesskabGyldighedTilsType[],
attrEgenskaber InteressefaellesskabEgenskaberAttrType[],
relationer InteressefaellesskabRelationType[]
);

CREATE TYPE InteressefaellesskabType AS
(
  id uuid,
  registrering InteressefaellesskabRegistreringType[]
);  



