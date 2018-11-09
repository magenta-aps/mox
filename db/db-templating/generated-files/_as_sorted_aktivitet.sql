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
        virkningSoeg TSTZRANGE,
        registreringObj AktivitetRegistreringType,
	    firstResult int,
	    maxResults int
        )
  RETURNS uuid[] AS
  $$
  DECLARE
          aktivitet_sorted_uuid uuid[];
          registreringSoeg TSTZRANGE;
  BEGIN

IF registreringObj IS NULL OR (registreringObj.registrering).timePeriod IS NULL THEN
   registreringSoeg = TSTZRANGE(current_timestamp, current_timestamp, '[]');
ELSE
    registreringSoeg = (registreringObj.registrering).timePeriod;
END IF;

aktivitet_sorted_uuid:=array(
       SELECT b.aktivitet_id
       FROM aktivitet_registrering b
       JOIN aktivitet_attr_egenskaber a ON a.aktivitet_registrering_id=b.id
       WHERE b.aktivitet_id = ANY (aktivitet_uuids)
             AND (b.registrering).timeperiod && registreringSoeg
             AND (a.virkning).timePeriod && virkningSoeg
       GROUP BY b.aktivitet_id
       ORDER BY array_agg(DISTINCT a.brugervendtnoegle), b.aktivitet_id
       LIMIT maxResults OFFSET firstResult
);

RETURN aktivitet_sorted_uuid;

END;
$$ LANGUAGE plpgsql STABLE;



