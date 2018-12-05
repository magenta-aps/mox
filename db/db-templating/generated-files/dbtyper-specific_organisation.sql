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

CREATE TYPE OrganisationGyldighedTils AS ENUM ('Aktiv','Inaktiv',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE OrganisationGyldighedTilsType AS (
    virkning Virkning,
    gyldighed OrganisationGyldighedTils
)
;



CREATE TYPE OrganisationEgenskaberAttrType AS (
brugervendtnoegle text,
organisationsnavn text,

 virkning Virkning
);




CREATE TYPE OrganisationRelationKode AS ENUM  ('branche','myndighed','myndighedstype','overordnet','produktionsenhed','skatteenhed','tilhoerer','virksomhed','virksomhedstype','adresser','ansatte','opgaver','tilknyttedebrugere','tilknyttedeenheder','tilknyttedefunktioner','tilknyttedeinteressefaellesskaber','tilknyttedeorganisationer','tilknyttedepersoner','tilknyttedeitsystemer');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_organisation_relation_kode_to_txt is invoked.



CREATE TYPE OrganisationRelationType AS (
  relType OrganisationRelationKode,
  virkning Virkning,
  uuid uuid,
  urn text,
  objektType text
)
;



CREATE TYPE OrganisationRegistreringType AS
(
registrering RegistreringBase,
tilsGyldighed OrganisationGyldighedTilsType[],
attrEgenskaber OrganisationEgenskaberAttrType[],
relationer OrganisationRelationType[]
);

CREATE TYPE OrganisationType AS
(
  id uuid,
  registrering OrganisationRegistreringType[]
);  





