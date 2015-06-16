-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klasse as_read.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_read_klasse(klasse_uuid uuid,
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange)
  RETURNS KlasseType AS
  $BODY$
SELECT 
*
FROM as_list_klasse(ARRAY[klasse_uuid],registrering_tstzrange,virkning_tstzrange)
LIMIT 1
 	$BODY$
LANGUAGE sql STABLE
;



