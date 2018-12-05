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

CREATE TYPE DokumentFremdriftTils AS ENUM ('Modtaget','Fordelt','Underudarbejdelse','Underreview','Publiceret','Endeligt','Afleveret',''); --'' means undefined (which is needed to clear previous defined tilstand_values in an already registered virksnings-periode)

CREATE TYPE DokumentFremdriftTilsType AS (
    virkning Virkning,
    fremdrift DokumentFremdriftTils
)
;



CREATE TYPE DokumentEgenskaberAttrType AS (
brugervendtnoegle text,
beskrivelse text,
brevdato ClearableDate,

kassationskode text,
major ClearableInt,

minor ClearableInt,

offentlighedundtaget offentlighedundtagettype,
titel text,
dokumenttype text,

 virkning Virkning
);




CREATE TYPE DokumentRelationKode AS ENUM  ('nyrevision','primaerklasse','ejer','ansvarlig','primaerbehandler','fordelttil','arkiver','besvarelser','udgangspunkter','kommentarer','bilag','andredokumenter','andreklasser','andrebehandlere','parter','kopiparter','tilknyttedesager');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_dokument_relation_kode_to_txt is invoked.



CREATE TYPE DokumentRelationType AS (
  relType DokumentRelationKode,
  virkning Virkning,
  uuid uuid,
  urn  text,
  objektType text
)
;


/**************************************************/
/*					DokumentDel                   */
/**************************************************/

CREATE TYPE DokumentdelRelationKode AS ENUM  ('underredigeringaf');  --WARNING: Changes to enum names requires MANUALLY rebuilding indexes where _as_convert_dokumentdel_relation_kode_to_txt is invoked.


CREATE TYPE DokumentDelEgenskaberType AS (
indeks ClearableInt,
indhold text,
lokation text,
mimetype text,
 virkning Virkning
);


CREATE TYPE DokumentdelRelationType AS (
  relType DokumentdelRelationKode,
  virkning Virkning,
  uuid uuid,
  urn  text,
  objektType text 
)
;

CREATE TYPE DokumentDelType AS
(
  deltekst text,
  egenskaber DokumentDelEgenskaberType[],
  relationer DokumentdelRelationType[]
);  



/**************************************************/
/*					Dokumentvariant               */
/**************************************************/

CREATE TYPE DokumentVariantEgenskaberType AS (
arkivering ClearableBoolean, 
delvisscannet ClearableBoolean, 
offentliggoerelse ClearableBoolean, 
produktion ClearableBoolean,
 virkning Virkning
);


CREATE TYPE DokumentVariantType AS
(
  varianttekst text,
  egenskaber DokumentVariantEgenskaberType[],
  dele DokumentDelType[]
);  

/**************************************************/


CREATE TYPE DokumentRegistreringType AS
(
registrering RegistreringBase,
tilsFremdrift DokumentFremdriftTilsType[],
attrEgenskaber DokumentEgenskaberAttrType[],
relationer DokumentRelationType[],
varianter DokumentVariantType[]
);

CREATE TYPE DokumentType AS
(
  id uuid,
  registrering DokumentRegistreringType[]
);  


CREATE TYPE _DokumentVariantDelKey AS
(
  varianttekst text,
  deltekst text
);




