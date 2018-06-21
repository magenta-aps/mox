-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py tilstand _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_tilstand(
        tilstand_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          tilstand_sorted_uuid uuid[];
  BEGIN

tilstand_sorted_uuid:=array(
SELECT b.tilstand_id
    FROM  tilstand_attr_egenskaber a
    JOIN (select distinct on (tilstand_id) tilstand_id, id from tilstand_registrering) b on a.tilstand_registrering_id=b.id
    WHERE b.tilstand_id = ANY (tilstand_uuids)
    order by a.brugervendtnoegle
         limit maxResults offset firstResult
);

RETURN tilstand_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;




