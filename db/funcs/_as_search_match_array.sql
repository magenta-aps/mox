
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


CREATE OR REPLACE FUNCTION _as_search_match_array(searchForArr text[], searchInArr text[])
RETURNS boolean LANGUAGE plpgsql AS 
$$
DECLARE

BEGIN

IF coalesce(array_length(searchForArr,1),0)=0 and coalesce(array_length(searchInArr,1),0)>0 THEN  
	RETURN false;
ELSE
	--RAISE NOTICE 'SQL part  searchForArr[%], searchInArr[%]',to_json(searchForArr),to_json(searchInArr);
	IF EXISTS (
	SELECT
	a.searchForElement,
	b.searchTargetElement
	FROM
	unnest(searchForArr) a(searchForElement)
	LEFT JOIN unnest(searchInArr) b(searchTargetElement) on b.searchTargetElement ilike a.searchForElement
	WHERE b.searchTargetElement IS NULL
	)
	THEN 
	RETURN FALSE;
	ELSE
	RETURN TRUE;
	END IF;

END IF;

END;
$$;