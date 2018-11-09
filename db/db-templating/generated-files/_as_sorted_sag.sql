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
        virkningSoeg TSTZRANGE,
        registreringObj SagRegistreringType,
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          sag_sorted_uuid uuid[];
          registreringSoeg TSTZRANGE;
  BEGIN

IF registreringObj IS NULL OR (registreringObj.registrering).timePeriod IS NULL THEN
   registreringSoeg = TSTZRANGE(current_timestamp, current_timestamp, '[]');
ELSE
    registreringSoeg = (registreringObj.registrering).timePeriod;
END IF;

sag_sorted_uuid:=array(
       SELECT b.sag_id
       FROM sag_registrering b
       JOIN sag_attr_egenskaber a ON a.sag_registrering_id=b.id
       WHERE b.sag_id = ANY (sag_uuids)
             AND (b.registrering).timeperiod && registreringSoeg
             AND (a.virkning).timePeriod && virkningSoeg
       GROUP BY b.sag_id
       ORDER BY array_agg(DISTINCT a.brugervendtnoegle), b.sag_id
       LIMIT maxResults OFFSET firstResult
);

RETURN sag_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;



