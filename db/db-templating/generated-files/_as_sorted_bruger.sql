-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py bruger _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_bruger(
        bruger_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          bruger_sorted_uuid uuid[];
  BEGIN

bruger_sorted_uuid:=array(
SELECT b.bruger_id
    FROM  bruger_registrering b
    JOIN (SELECT DISTINCT ON (bruger_registrering_id) bruger_registrering_id, id, brugervendtnoegle FROM bruger_attr_egenskaber) a ON a.bruger_registrering_id=b.id    
    WHERE b.bruger_id = ANY (bruger_uuids)
    ORDER BY a.brugervendtnoegle
         LIMIT maxResults OFFSET firstResult
);

RETURN bruger_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;



