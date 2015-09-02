-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klasse dbtyper-specific.jinja.sql AND applying a patch (dbtyper-specific_klasse.sql.diff)
*/

--create custom type sans db-ids to be able to do "clean" function signatures "for the outside world".

CREATE TYPE KlassePubliceretTils AS ENUM ('Publiceret','IkkePubliceret',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE KlassePubliceretTilsType AS (
    virkning Virkning,
    publiceret KlassePubliceretTils
)
;

CREATE TYPE KlasseSoegeordType AS (
soegeordidentifikator text,
beskrivelse text,
soegeordskategori text
)
;

CREATE TYPE KlasseEgenskaberAttrType AS (
brugervendtnoegle text,
beskrivelse text,
eksempel text,
omfang text,
titel text,
retskilde text,
aendringsnotat text,
soegeord KlasseSoegeordType[],
 virkning Virkning
);


CREATE TYPE KlasseRelationKode AS ENUM  ('ejer','ansvarlig','overordnetklasse','facet','redaktoerer','sideordnede','mapninger','tilfoejelser','erstatter','lovligekombinationer');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_klasse_relation_kode_to_txt is invoked.

CREATE TYPE KlasseRelationType AS (
  relType KlasseRelationKode,
  virkning Virkning,
  uuid uuid,
  urn  text,
  objektType text 
)
;

CREATE TYPE KlasseRegistreringType AS
(
registrering RegistreringBase,
tilsPubliceret KlassePubliceretTilsType[],
attrEgenskaber KlasseEgenskaberAttrType[],
relationer KlasseRelationType[]
);

CREATE TYPE KlasseType AS
(
  id uuid,
  registrering KlasseRegistreringType[]
);  



