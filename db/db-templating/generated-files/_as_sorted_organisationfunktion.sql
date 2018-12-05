-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/


CREATE OR REPLACE FUNCTION _as_sorted_organisationfunktion(
    organisationfunktion_uuids uuid[],
    virkningSoeg TSTZRANGE,
    registreringObj    OrganisationfunktionRegistreringType,
    firstResult int,
    maxResults int
) RETURNS uuid[] AS $$
DECLARE
    organisationfunktion_sorted_uuid uuid[];
    registreringSoeg TSTZRANGE;
BEGIN
    IF registreringObj IS NULL OR (registreringObj.registrering).timePeriod IS NULL THEN
        registreringSoeg = TSTZRANGE(current_timestamp, current_timestamp, '[]');
    ELSE
        registreringSoeg = (registreringObj.registrering).timePeriod;
    END IF;

    organisationfunktion_sorted_uuid:=array(
          SELECT b.organisationfunktion_id
            FROM organisationfunktion_registrering b
            JOIN organisationfunktion_attr_egenskaber a ON a.organisationfunktion_registrering_id=b.id
           WHERE b.organisationfunktion_id = ANY (organisationfunktion_uuids)
             AND (b.registrering).timeperiod && registreringSoeg
             AND (a.virkning).timePeriod && virkningSoeg
        GROUP BY b.organisationfunktion_id
        ORDER BY array_agg(DISTINCT a.brugervendtnoegle), b.organisationfunktion_id
           LIMIT maxResults OFFSET firstResult
    );

    RETURN organisationfunktion_sorted_uuid;
END;
$$ LANGUAGE plpgsql STABLE;


