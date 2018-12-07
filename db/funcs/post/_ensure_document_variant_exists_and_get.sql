
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


CREATE OR REPLACE FUNCTION _ensure_document_variant_exists_and_get(reg_id bigint,current_variant_text text)
RETURNS int LANGUAGE plpgsql AS 
$$
DECLARE
res_variant_id bigint;
BEGIN


SELECT a.id into res_variant_id 
FROM dokument_variant a 
WHERE 
a.dokument_registrering_id=reg_id
and a.varianttekst=current_variant_text
;

IF res_variant_id IS NULL THEN

res_variant_id:=nextval('dokument_variant_id_seq'::regclass);

 INSERT INTO dokument_variant (
    id,
      varianttekst,
        dokument_registrering_id
  )
  VALUES
  (
    res_variant_id,
      current_variant_text,
        reg_id
  ); 

END IF;

RETURN res_variant_id;

END;
$$;