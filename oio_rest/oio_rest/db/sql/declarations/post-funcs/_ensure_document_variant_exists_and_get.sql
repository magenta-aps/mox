-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


CREATE OR REPLACE FUNCTION _ensure_document_variant_exists_and_get (reg_id bigint, current_variant_text text)
    RETURNS int AS $$
DECLARE
    res_variant_id bigint;
BEGIN
    SELECT
        a.id INTO res_variant_id
    FROM
        dokument_variant a
    WHERE
        a.dokument_registrering_id = reg_id
        AND a.varianttekst = current_variant_text;
    IF res_variant_id IS NULL THEN
        res_variant_id := nextval('dokument_variant_id_seq'::regclass);
        INSERT INTO dokument_variant (id, varianttekst, dokument_registrering_id)
            VALUES (res_variant_id, current_variant_text, reg_id);
    END IF;
    RETURN res_variant_id;
END;
$$ LANGUAGE plpgsql;
