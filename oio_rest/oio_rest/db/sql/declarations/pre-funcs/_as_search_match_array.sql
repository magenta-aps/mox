-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


CREATE OR REPLACE FUNCTION _as_search_match_array (searchForArr text[], searchInArr text[])
    RETURNS boolean AS $$
DECLARE
BEGIN
    IF coalesce(array_length(searchForArr, 1), 0) = 0 AND coalesce(array_length(searchInArr, 1), 0) > 0 THEN
        RETURN FALSE;
    ELSE
        -- RAISE NOTICE 'SQL part searchForArr[%], searchInArr[%]', to_json(searchForArr), to_json(searchInArr);
        IF EXISTS (
                SELECT
                    a.searchForElement,
                    b.searchTargetElement
                FROM
                    unnest(searchForArr) a (searchForElement)
                    LEFT JOIN unnest(searchInArr) b (searchTargetElement) ON b.searchTargetElement ILIKE a.searchForElement
                WHERE
                    b.searchTargetElement IS NULL) THEN
                RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;
