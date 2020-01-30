-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


CREATE OR REPLACE FUNCTION _ensure_document_del_exists_and_get (reg_id bigint, current_variant_id bigint, current_deltekst text)
    RETURNS int AS $$
DECLARE
    res_del_id bigint;
BEGIN
    SELECT
        b.id INTO res_del_id
    FROM
        dokument_variant a
        JOIN dokument_del b ON b.variant_id = a.id
    WHERE
        a.dokument_registrering_id = reg_id
        AND a.id = current_variant_id
        AND b.deltekst = current_deltekst;
    IF res_del_id IS NULL THEN
        res_del_id := nextval('dokument_del_id_seq'::regclass);
        INSERT INTO dokument_del (id, deltekst, variant_id)
            VALUES (res_del_id, current_deltekst, current_variant_id);
    END IF;
    RETURN res_del_id;
END;
$$ LANGUAGE plpgsql;
