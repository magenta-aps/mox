-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/


CREATE OR REPLACE FUNCTION _as_get_prev_organisationenhed_registrering(organisationenhed_registrering)
  RETURNS organisationenhed_registrering AS
  $BODY$
  SELECT  * FROM organisationenhed_registrering as a WHERE
    organisationenhed_id = $1.organisationenhed_id 
    AND UPPER((a.registrering).TimePeriod) = LOWER(($1.registrering).TimePeriod) 
    AND UPPER_INC((a.registrering).TimePeriod) <> LOWER_INC(($1.registrering).TimePeriod)
    LIMIT 1 --constraints on timeperiod will also ensure max 1 hit
    $BODY$
  LANGUAGE sql STABLE
;


