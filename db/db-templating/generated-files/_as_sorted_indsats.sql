-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py indsats _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_indsats(
        indsats_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          indsats_sorted_uuid uuid[];
  BEGIN

indsats_sorted_uuid:=array(
SELECT b.indsats_id
    FROM  indsats_registrering b
    JOIN (SELECT DISTINCT ON (indsats_registrering_id) indsats_registrering_id, id, brugervendtnoegle FROM indsats_attr_egenskaber) a ON a.indsats_registrering_id=b.id    
    WHERE b.indsats_id = ANY (indsats_uuids)
    ORDER BY a.brugervendtnoegle
         LIMIT maxResults OFFSET firstResult
);

RETURN indsats_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;



