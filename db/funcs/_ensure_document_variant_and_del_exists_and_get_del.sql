
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


CREATE OR REPLACE FUNCTION _ensure_document_variant_and_del_exists_and_get_del(reg_id bigint,current_variant_text text, current_deltekst text)
RETURNS int LANGUAGE plpgsql AS 
$$
DECLARE
current_del_id bigint;
current_variant_id bigint;
BEGIN

current_variant_id:=_ensure_document_variant_exists_and_get(reg_id,current_variant_text);
current_del_id:=_ensure_document_del_exists_and_get(reg_id, current_variant_id, current_deltekst);

RETURN current_del_id;

END;
$$;