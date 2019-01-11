-- Copyright (C) 2015 Magenta ApS, https://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

-- Just returns the 'TimePeriod' field of the type passed in.
-- Used to work around limitations of PostgreSQL's exclusion constraints.
CREATE OR REPLACE FUNCTION _composite_type_to_time_range(ANYELEMENT) RETURNS
  TSTZRANGE AS 'SELECT $1.TimePeriod' LANGUAGE sql STRICT IMMUTABLE;



CREATE OR REPLACE FUNCTION _uuid_to_text(UUID) RETURNS TEXT AS 'SELECT $1::TEXT' LANGUAGE sql IMMUTABLE;

