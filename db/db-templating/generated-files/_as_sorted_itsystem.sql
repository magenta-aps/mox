-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py itsystem _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_itsystem(
        itsystem_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          itsystem_sorted_uuid uuid[];
  BEGIN

itsystem_sorted_uuid:=array(
SELECT b.itsystem_id
    FROM  itsystem_attr_egenskaber a
    JOIN (select distinct on (itsystem_id) itsystem_id, id from itsystem_registrering) b on a.itsystem_registrering_id=b.id
    WHERE b.itsystem_id = ANY (itsystem_uuids)
    order by a.brugervendtnoegle
         limit maxResults offset firstResult
);

RETURN itsystem_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;




