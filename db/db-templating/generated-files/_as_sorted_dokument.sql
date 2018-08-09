-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py dokument _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_dokument(
        dokument_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          dokument_sorted_uuid uuid[];
  BEGIN

dokument_sorted_uuid:=array(
SELECT b.dokument_id
    FROM  dokument_registrering b
    JOIN (SELECT DISTINCT ON (dokument_registrering_id) dokument_registrering_id, id, brugervendtnoegle FROM dokument_attr_egenskaber) a ON a.dokument_registrering_id=b.id    
    WHERE b.dokument_id = ANY (dokument_uuids)
    ORDER BY a.brugervendtnoegle
         LIMIT maxResults OFFSET firstResult
);

RETURN dokument_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;



