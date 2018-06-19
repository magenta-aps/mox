-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klassifikation _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_klassifikation(
        klassifikation_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          klassifikation_sorted_uuid uuid[];
  BEGIN

klassifikation_sorted_uuid:=array(
SELECT b.klassifikation_id
    FROM  klassifikation_attr_egenskaber a
    JOIN klassifikation_registrering b on a.klassifikation_registrering_id=b.id
    WHERE b.klassifikation_id = ANY (klassifikation_uuids)
    order by a.brugervendtnoegle
         limit maxResults offset firstResult
);

RETURN klassifikation_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;




