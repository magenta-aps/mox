-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py organisationfunktion _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_organisationfunktion(
        organisationfunktion_uuids uuid[],
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          organisationfunktion_sorted_uuid uuid[];
  BEGIN

organisationfunktion_sorted_uuid:=array(
SELECT b.organisationfunktion_id
    FROM  organisationfunktion_registrering b
    JOIN (SELECT DISTINCT ON (organisationfunktion_registrering_id) organisationfunktion_registrering_id, id, brugervendtnoegle FROM organisationfunktion_attr_egenskaber) a ON a.organisationfunktion_registrering_id=b.id    
    WHERE b.organisationfunktion_id = ANY (organisationfunktion_uuids)
    ORDER BY a.brugervendtnoegle
         LIMIT maxResults OFFSET firstResult
);

RETURN organisationfunktion_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;



