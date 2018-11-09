-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/

CREATE OR REPLACE FUNCTION as_read_indsats(indsats_uuid uuid,
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange,
  auth_criteria_arr IndsatsRegistreringType[]=null
  )
  RETURNS IndsatsType AS
  $$
DECLARE
	resArr IndsatsType[];
BEGIN  
resArr:= as_list_indsats(ARRAY[indsats_uuid],registrering_tstzrange,virkning_tstzrange,auth_criteria_arr);
IF resArr is not null and coalesce(array_length(resArr,1),0)=1 THEN
	RETURN resArr[1];
ELSE
	RETURN null;
END IF;

END;
$$ LANGUAGE plpgsql STABLE
;



