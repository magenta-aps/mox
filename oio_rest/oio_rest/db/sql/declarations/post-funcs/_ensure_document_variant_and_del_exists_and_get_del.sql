-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


CREATE OR REPLACE FUNCTION _ensure_document_variant_and_del_exists_and_get_del (reg_id bigint, current_variant_text text, current_deltekst text)
    RETURNS int AS $$
DECLARE
    current_del_id bigint;
    current_variant_id bigint;
BEGIN
    current_variant_id := _ensure_document_variant_exists_and_get (reg_id,
        current_variant_text);
    current_del_id := _ensure_document_del_exists_and_get (reg_id,
        current_variant_id,
        current_deltekst);
    RETURN current_del_id;
END;
$$ LANGUAGE plpgsql;
