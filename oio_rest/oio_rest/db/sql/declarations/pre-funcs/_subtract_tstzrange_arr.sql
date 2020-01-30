-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


--Subtract all of the tstzranges in the array from the first tstzrange given. 
CREATE OR REPLACE FUNCTION _subtract_tstzrange_arr (rangeA tstzrange, rangeArr tstzrange[])
    RETURNS tstzrange[] AS $$
DECLARE
    result tstzrange[];
    temp_result tstzrange[];
    rangeB tstzrange;
    rangeA_leftover tstzrange;
BEGIN
    result[1] := rangeA;
    IF rangeArr IS NOT NULL THEN
        FOREACH rangeB IN ARRAY rangeArr LOOP
            temp_result := result;
            result := '{}';
            FOREACH rangeA_leftover IN ARRAY temp_result LOOP
                result := array_cat(result, _subtract_tstzrange (rangeA_leftover, rangeB));
            END LOOP;
        END LOOP;
    END IF;
    RETURN result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

