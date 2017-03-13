-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py indsats _as_get_prev_registrering.jinja.sql
*/


CREATE OR REPLACE FUNCTION _as_get_prev_indsats_registrering(indsats_registrering)
  RETURNS indsats_registrering AS
  $BODY$
  SELECT  * FROM indsats_registrering as a WHERE
    indsats_id = $1.indsats_id 
    AND UPPER((a.registrering).TimePeriod) = LOWER(($1.registrering).TimePeriod) 
    AND UPPER_INC((a.registrering).TimePeriod) <> LOWER_INC(($1.registrering).TimePeriod)
    LIMIT 1 --constraints on timeperiod will also ensure max 1 hit
    $BODY$
  LANGUAGE sql STABLE
;


