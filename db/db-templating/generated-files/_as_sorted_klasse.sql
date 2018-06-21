-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klasse _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_klasse(
        klasse_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          klasse_sorted_uuid uuid[];
  BEGIN

klasse_sorted_uuid:=array(
SELECT b.klasse_id
    FROM  klasse_registrering b
    JOIN (SELECT DISTINCT ON (klasse_registrering_id) klasse_registrering_id, id, brugervendtnoegle FROM klasse_attr_egenskaber) a ON a.klasse_registrering_id=b.id    
    WHERE b.klasse_id = ANY (klasse_uuids)
    ORDER BY a.brugervendtnoegle
         LIMIT maxResults OFFSET firstResult
);

RETURN klasse_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;



