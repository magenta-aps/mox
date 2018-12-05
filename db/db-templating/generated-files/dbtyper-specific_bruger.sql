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

CREATE TYPE BrugerGyldighedTils AS ENUM ('Aktiv','Inaktiv',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE BrugerGyldighedTilsType AS (
    virkning Virkning,
    gyldighed BrugerGyldighedTils
)
;



CREATE TYPE BrugerEgenskaberAttrType AS (
brugervendtnoegle text,
brugernavn text,
brugertype text,

 virkning Virkning
);




CREATE TYPE BrugerRelationKode AS ENUM  ('tilhoerer','adresser','brugertyper','opgaver','tilknyttedeenheder','tilknyttedefunktioner','tilknyttedeinteressefaellesskaber','tilknyttedeorganisationer','tilknyttedepersoner','tilknyttedeitsystemer');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_bruger_relation_kode_to_txt is invoked.



CREATE TYPE BrugerRelationType AS (
  relType BrugerRelationKode,
  virkning Virkning,
  uuid uuid,
  urn text,
  objektType text
)
;



CREATE TYPE BrugerRegistreringType AS
(
registrering RegistreringBase,
tilsGyldighed BrugerGyldighedTilsType[],
attrEgenskaber BrugerEgenskaberAttrType[],
relationer BrugerRelationType[]
);

CREATE TYPE BrugerType AS
(
  id uuid,
  registrering BrugerRegistreringType[]
);  





