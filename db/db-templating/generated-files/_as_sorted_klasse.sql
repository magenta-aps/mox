-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klasse _as_sorted.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_sorted_klasse(
        klasse_uuids uuid[],
        virkningSoeg TSTZRANGE,
        registreringObj KlasseRegistreringType,
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          klasse_sorted_uuid uuid[];
          registreringSoeg TSTZRANGE;
  BEGIN

IF registreringObj IS NULL OR (registreringObj.registrering).timePeriod IS NULL THEN
   registreringSoeg = TSTZRANGE(current_timestamp, current_timestamp, '[]');
ELSE
    registreringSoeg = (registreringObj.registrering).timePeriod;
END IF;

klasse_sorted_uuid:=array(
       SELECT b.klasse_id
       FROM klasse_registrering b
       JOIN klasse_attr_egenskaber a ON a.klasse_registrering_id=b.id
       WHERE b.klasse_id = ANY (klasse_uuids)
             AND (b.registrering).timeperiod && registreringSoeg
             AND (a.virkning).timePeriod && virkningSoeg
       GROUP BY b.klasse_id
       ORDER BY array_agg(DISTINCT a.brugervendtnoegle), b.klasse_id
       LIMIT maxResults OFFSET firstResult
);

RETURN klasse_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;



