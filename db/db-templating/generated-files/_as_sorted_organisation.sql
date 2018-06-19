-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py organisation _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_organisation(
        organisation_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          organisation_sorted_uuid uuid[];
  BEGIN

organisation_sorted_uuid:=array(
SELECT b.organisation_id
    FROM  organisation_attr_egenskaber a
    JOIN organisation_registrering b on a.organisation_registrering_id=b.id
    WHERE b.organisation_id = ANY (organisation_uuids)
    order by a.brugervendtnoegle
         limit maxResults offset firstResult
);

RETURN organisation_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;




