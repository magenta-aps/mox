-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py interessefaellesskab _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_interessefaellesskab(
        interessefaellesskab_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          interessefaellesskab_sorted_uuid uuid[];
  BEGIN

interessefaellesskab_sorted_uuid:=array(
SELECT b.interessefaellesskab_id
    FROM  interessefaellesskab_attr_egenskaber a
    JOIN interessefaellesskab_registrering b on a.interessefaellesskab_registrering_id=b.id
    WHERE b.interessefaellesskab_id = ANY (interessefaellesskab_uuids)
    order by a.brugervendtnoegle
         limit maxResults offset firstResult
);

RETURN interessefaellesskab_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;




