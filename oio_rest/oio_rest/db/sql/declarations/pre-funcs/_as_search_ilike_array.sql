-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


CREATE OR REPLACE FUNCTION _as_search_ilike_array (searchFor text, searchInArr text[])
    RETURNS boolean AS $$
DECLARE
BEGIN
    IF searchFor IS NULL OR coalesce(array_length(searchInArr, 1), 0) = 0 THEN
        RETURN FALSE;
    ELSE
        -- RAISE NOTICE 'SQL part searchForArr[%], searchInArr[%]',to_json(searchForArr),to_json(searchInArr);
        IF EXISTS (
                SELECT
                    a.searchInElement
                FROM
                    unnest(searchInArr) a (searchInElement)
                WHERE
                    a.searchInElement ILIKE searchFor) THEN
                RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;
