-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


CREATE TYPE AktoerTypeKode AS ENUM (
    'Organisation',
    'OrganisationEnhed',
    'OrganisationFunktion',
    'Bruger',
    'ItSystem',
    'Interessefaellesskab'
);


CREATE TYPE Virkning AS (
    TimePeriod TSTZRANGE,
    AktoerRef UUID,
    AktoerTypeKode AktoerTypeKode,
    NoteTekst TEXT
);


CREATE TYPE LivscyklusKode AS ENUM (
    'Opstaaet',
    'Importeret',
    'Passiveret',
    'Slettet',
    'Rettet'
);


 --should be renamed to Registrering, when the old 'Registrering'-type is replaced
CREATE TYPE RegistreringBase AS (
    timeperiod tstzrange,
    livscykluskode livscykluskode,
    brugerref uuid,
    note text
);


CREATE TYPE OffentlighedundtagetType AS (
    AlternativTitel text,
    Hjemmel text
);


/****************************************/
CREATE TYPE ClearableInt AS (
    value int,
    cleared boolean
);


CREATE TYPE ClearableDate AS (
    value date,
    cleared boolean
);


CREATE TYPE ClearableBoolean AS (
    value boolean,
    cleared boolean
);


CREATE TYPE ClearableTimestamptz AS (
    value timestamptz,
    cleared boolean
);


CREATE TYPE ClearableInterval AS (
    value interval(0),
    cleared boolean
);


/****************************************/
CREATE OR REPLACE FUNCTION actual_state._cast_ClearableInt_to_int (clearable_int ClearableInt)
    RETURNS int AS $$
DECLARE
BEGIN
    IF clearable_int IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN clearable_int.value;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(ClearableInt AS int)
WITH FUNCTION actual_state._cast_ClearableInt_to_int (ClearableInt)
AS implicit;


CREATE OR REPLACE FUNCTION actual_state._cast_int_to_ClearableInt (int_value int)
    RETURNS ClearableInt AS $$
DECLARE
BEGIN
    IF int_value IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN ROW (int_value, NULL)::ClearableInt;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(int AS ClearableInt)
WITH FUNCTION actual_state._cast_int_to_ClearableInt (int)
AS implicit;


CREATE OR REPLACE FUNCTION actual_state._cast_text_to_ClearableInt (text_value text)
    RETURNS ClearableInt AS $$
DECLARE
BEGIN
    IF text_value IS NULL THEN
        RETURN NULL;
    ELSE
        IF text_value <> '' THEN
            RAISE
            EXCEPTION 'Unable to cast text value [%] to ClearableInt. Only empty text is allowed (or null).', text_value
                USING ERRCODE = 22000;
        ELSE
            RETURN ROW (NULL, TRUE)::ClearableInt;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(text AS ClearableInt)
WITH FUNCTION actual_state._cast_text_to_ClearableInt (text)
AS implicit;


/**************************************************************************/
CREATE OR REPLACE FUNCTION actual_state._cast_ClearableDate_to_date (clearable_date ClearableDate)
    RETURNS date AS $$
DECLARE
BEGIN
    IF clearable_date IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN clearable_date.value;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(ClearableDate AS date)
WITH FUNCTION actual_state._cast_ClearableDate_to_date (ClearableDate)
AS implicit;


CREATE OR REPLACE FUNCTION actual_state._cast_date_to_ClearableDate (date_value date)
    RETURNS ClearableDate AS $$
DECLARE
BEGIN
    IF date_value IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN ROW (date_value, NULL)::ClearableDate;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(date AS ClearableDate)
WITH FUNCTION actual_state._cast_date_to_ClearableDate (date)
AS implicit;


CREATE OR REPLACE FUNCTION actual_state._cast_text_to_ClearableDate (text_value text)
    RETURNS ClearableDate AS $$
DECLARE
BEGIN
    IF text_value IS NULL THEN
        RETURN NULL;
    ELSE
        IF text_value <> '' THEN
            RAISE
            EXCEPTION 'Unable to cast text value [%] to ClearableDate. Only empty text is allowed (or null).', text_value
                USING ERRCODE = 22000;
        ELSE
            RETURN ROW (NULL, TRUE)::ClearableDate;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(text AS ClearableDate)
WITH FUNCTION actual_state._cast_text_to_ClearableDate (text)
AS implicit;


/**************************************************************************/
CREATE OR REPLACE FUNCTION actual_state._cast_ClearableBoolean_to_boolean (clearable_boolean ClearableBoolean)
    RETURNS boolean AS $$
DECLARE
BEGIN
    IF clearable_boolean IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN clearable_boolean.value;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(ClearableBoolean AS boolean)
WITH FUNCTION actual_state._cast_ClearableBoolean_to_boolean (ClearableBoolean)
AS implicit;


CREATE OR REPLACE FUNCTION actual_state._cast_boolean_to_ClearableBoolean (boolean_value boolean)
    RETURNS ClearableBoolean AS $$
DECLARE
BEGIN
    IF boolean_value IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN ROW (boolean_value, NULL)::ClearableBoolean;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(boolean AS ClearableBoolean)
WITH FUNCTION actual_state._cast_boolean_to_ClearableBoolean (boolean)
AS implicit;


CREATE OR REPLACE FUNCTION actual_state._cast_text_to_ClearableBoolean (text_value text)
    RETURNS ClearableBoolean AS $$
DECLARE
BEGIN
    IF text_value IS NULL THEN
        RETURN NULL;
    ELSE
        IF text_value <> '' THEN
            RAISE
            EXCEPTION 'Unable to cast text value [%] to ClearableBoolean. Only empty text is allowed (or null).', text_value
                USING ERRCODE = 22000;
        ELSE
            RETURN ROW (NULL, TRUE)::ClearableBoolean;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(text AS ClearableBoolean)
WITH FUNCTION actual_state._cast_text_to_ClearableBoolean (text)
AS implicit;


/**************************************************************************/
CREATE OR REPLACE FUNCTION actual_state._cast_ClearableTimestamptz_to_timestamptz (clearable_timestamptz ClearableTimestamptz)
    RETURNS timestamptz AS $$
DECLARE
BEGIN
    IF clearable_timestamptz IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN clearable_timestamptz.value;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(ClearableTimestamptz AS timestamptz)
WITH FUNCTION actual_state._cast_ClearableTimestamptz_to_timestamptz (ClearableTimestamptz)
AS implicit;


CREATE OR REPLACE FUNCTION actual_state._cast_timestamptz_to_ClearableTimestamptz (timestamptz_value timestamptz)
    RETURNS ClearableTimestamptz AS $$
DECLARE
BEGIN
    IF timestamptz_value IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN ROW (timestamptz_value, NULL)::ClearableTimestamptz;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(timestamptz AS ClearableTimestamptz)
WITH FUNCTION actual_state._cast_timestamptz_to_ClearableTimestamptz (timestamptz)
AS implicit;


CREATE OR REPLACE FUNCTION actual_state._cast_text_to_ClearableTimestamptz (text_value text)
    RETURNS ClearableTimestamptz AS $$
DECLARE
BEGIN
    IF text_value IS NULL THEN
        RETURN NULL;
    ELSE
        IF text_value <> '' THEN
            RAISE
            EXCEPTION 'Unable to cast text value [%] to ClearableTimestamptz. Only empty text is allowed (or null).', text_value
                USING ERRCODE = 22000;
        ELSE
            RETURN ROW (NULL, TRUE)::ClearableTimestamptz;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(text AS ClearableTimestamptz)
WITH FUNCTION actual_state._cast_text_to_ClearableTimestamptz (text)
AS implicit;


/**************************************************************************/
CREATE OR REPLACE FUNCTION actual_state._cast_ClearableInterval_to_interval (clearable_interval ClearableInterval)
    RETURNS interval(0) AS $$
DECLARE
BEGIN
    IF clearable_interval IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN clearable_interval.value;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(ClearableInterval AS interval(0))
WITH FUNCTION actual_state._cast_ClearableInterval_to_interval (ClearableInterval)
AS implicit;


CREATE OR REPLACE FUNCTION actual_state._cast_interval_to_ClearableInterval (interval_value interval(0))
    RETURNS ClearableInterval AS $$
DECLARE
BEGIN
    IF interval_value IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN ROW (interval_value, NULL)::ClearableInterval;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(interval(0) AS ClearableInterval)
WITH FUNCTION actual_state._cast_interval_to_ClearableInterval (interval)
AS implicit;


CREATE OR REPLACE FUNCTION actual_state._cast_text_to_ClearableInterval (text_value text)
    RETURNS ClearableInterval AS $$
DECLARE
BEGIN
    IF text_value IS NULL THEN
        RETURN NULL;
    ELSE
        IF text_value <> '' THEN
            RAISE
            EXCEPTION 'Unable to cast text value [%] to ClearableInterval. Only empty text is allowed (or null).', text_value
                USING ERRCODE = 22000;
        ELSE
            RETURN ROW (NULL, TRUE)::ClearableInterval;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE CAST(text AS ClearableInterval)
WITH FUNCTION actual_state._cast_text_to_ClearableInterval (text)
AS implicit;
