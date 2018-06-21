-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py sag _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_sag(
        sag_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          sag_sorted_uuid uuid[];
  BEGIN

sag_sorted_uuid:=array(
SELECT b.sag_id
    FROM  sag_attr_egenskaber a
    JOIN (SELECT DISTINCT ON (sag_id) sag_id, id FROM sag_registrering) b ON a.sag_registrering_id=b.id
    WHERE b.sag_id = ANY (sag_uuids)
    ORDER BY a.brugervendtnoegle
         LIMIT maxResults OFFSET firstResult
);

RETURN sag_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;




