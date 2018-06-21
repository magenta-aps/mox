-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py aktivitet _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_aktivitet(
        aktivitet_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          aktivitet_sorted_uuid uuid[];
  BEGIN

aktivitet_sorted_uuid:=array(
SELECT b.aktivitet_id
    FROM  aktivitet_attr_egenskaber a
    JOIN (SELECT DISTINCT ON (aktivitet_id) aktivitet_id, id FROM aktivitet_registrering) b ON a.aktivitet_registrering_id=b.id
    WHERE b.aktivitet_id = ANY (aktivitet_uuids)
    ORDER BY a.brugervendtnoegle
         LIMIT maxResults OFFSET firstResult
);

RETURN aktivitet_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;




