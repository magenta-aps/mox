-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py facet _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_facet(
        facet_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          facet_sorted_uuid uuid[];
  BEGIN

facet_sorted_uuid:=array(
SELECT b.facet_id
    FROM  facet_attr_egenskaber a
    JOIN (SELECT DISTINCT ON (facet_id) facet_id, id FROM facet_registrering) b ON a.facet_registrering_id=b.id
    WHERE b.facet_id = ANY (facet_uuids)
    ORDER BY a.brugervendtnoegle
         LIMIT maxResults OFFSET firstResult
);

RETURN facet_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;




