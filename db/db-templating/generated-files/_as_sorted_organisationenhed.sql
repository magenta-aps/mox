-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py organisationenhed _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_organisationenhed(
        organisationenhed_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          organisationenhed_sorted_uuid uuid[];
  BEGIN

organisationenhed_sorted_uuid:=array(
SELECT b.organisationenhed_id
    FROM  organisationenhed_attr_egenskaber a
    JOIN (SELECT DISTINCT ON (organisationenhed_id) organisationenhed_id, id FROM organisationenhed_registrering) b ON a.organisationenhed_registrering_id=b.id
    WHERE b.organisationenhed_id = ANY (organisationenhed_uuids)
    ORDER BY a.brugervendtnoegle
         LIMIT maxResults OFFSET firstResult
);

RETURN organisationenhed_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;




