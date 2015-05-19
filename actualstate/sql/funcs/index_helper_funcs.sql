/******************** FUNCTIONS (NEEDED FOR TABLE/INDEX-DEFS) DEFS ***********************************/

-- Just returns the 'TimePeriod' field of the type passed in.
-- Used to work around limitations of PostgreSQL's exclusion constraints.
CREATE OR REPLACE FUNCTION composite_type_to_time_range(ANYELEMENT) RETURNS
  TSTZRANGE AS 'SELECT $1.TimePeriod' LANGUAGE sql STRICT IMMUTABLE;



CREATE OR REPLACE FUNCTION uuid_to_text(UUID) RETURNS TEXT AS 'SELECT $1::TEXT' LANGUAGE sql IMMUTABLE;


-- Just returns the 'TimePeriod' field of the type passed in.
-- Used to work around limitations of PostgreSQL's exclusion constraints.
CREATE OR REPLACE FUNCTION composite_type_to_time_range(ANYELEMENT) RETURNS
  TSTZRANGE AS 'SELECT $1.TimePeriod' LANGUAGE sql STRICT IMMUTABLE;
