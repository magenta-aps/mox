-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

CREATE TYPE OrganisationfunktionGyldighedTils AS ENUM ('Aktiv','Inaktiv',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE OrganisationfunktionGyldighedTilsType AS (
    virkning Virkning,
    gyldighed OrganisationfunktionGyldighedTils
)
;



CREATE TYPE OrganisationfunktionEgenskaberAttrType AS (
brugervendtnoegle text,
funktionsnavn text,

 virkning Virkning
);




CREATE TYPE OrganisationfunktionRelationKode AS ENUM  ('organisatoriskfunktionstype','adresser','opgaver','tilknyttedebrugere','tilknyttedeenheder','tilknyttedeorganisationer','tilknyttedeitsystemer','tilknyttedeinteressefaellesskaber','tilknyttedepersoner');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_organisationfunktion_relation_kode_to_txt is invoked.



CREATE TYPE OrganisationfunktionRelationType AS (
  relType OrganisationfunktionRelationKode,
  virkning Virkning,
  uuid uuid,
  urn  text,
  objektType text
)
;



CREATE TYPE OrganisationfunktionRegistreringType AS
(
registrering RegistreringBase,
tilsGyldighed OrganisationfunktionGyldighedTilsType[],
attrEgenskaber OrganisationfunktionEgenskaberAttrType[],
relationer OrganisationfunktionRelationType[]
);

CREATE TYPE OrganisationfunktionType AS
(
  id uuid,
  registrering OrganisationfunktionRegistreringType[]
);  





