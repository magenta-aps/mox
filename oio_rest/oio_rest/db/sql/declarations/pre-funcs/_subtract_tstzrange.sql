-- SPDX-FileCopyrightText: 2018-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


--Subtract the second tstzrange from the first tstzrange given. 
CREATE OR REPLACE FUNCTION _subtract_tstzrange (rangeA tstzrange, rangeB tstzrange)
    RETURNS tstzrange[] AS $$
DECLARE
    result tstzrange[];
    str_tzrange1_inc_excl text;
    str_tzrange2_inc_excl text;
    result_non_cont_part_a tstzrange;
    result_non_cont_part_b tstzrange;
BEGIN
    IF rangeA && rangeB THEN
        --identify the special case the a subtraction of the ranges, would result in a non continuous range.
        IF rangeA @> lower(rangeB) AND rangeA @> upper(rangeB) AND NOT --make sure that rangeA @> lower(rangeB) actually holds true, considering inc/exc.
            (lower(rangeA) = lower(rangeB) AND lower_inc(rangeB) AND NOT lower_inc(rangeA)) AND NOT
            --make sure that rangeA @> upper(rangeB) actually holds true, considering inc/exc.
            (upper(rangeA) = upper(rangeB) AND upper_inc(rangeB) AND NOT upper_inc(rangeA)) THEN
            IF lower_inc(rangeA) THEN
                str_tzrange1_inc_excl := '[';
            ELSE
                str_tzrange1_inc_excl := '(';
            END IF;
            IF lower_inc(rangeB) THEN
                str_tzrange1_inc_excl := str_tzrange1_inc_excl || ')';
            ELSE
                str_tzrange1_inc_excl := str_tzrange1_inc_excl || ']';
            END IF;
            IF upper_inc(rangeB) THEN
                str_tzrange2_inc_excl := '(';
            ELSE
                str_tzrange2_inc_excl := '[';
            END IF;
            IF upper_inc(rangeA) THEN
                str_tzrange2_inc_excl := str_tzrange2_inc_excl || ']';
            ELSE
                str_tzrange2_inc_excl := str_tzrange2_inc_excl || ')';
            END IF;
            result_non_cont_part_a := tstzrange(lower(rangeA), lower(rangeB), str_tzrange1_inc_excl);
            result_non_cont_part_b := tstzrange(upper(rangeB), upper(rangeA), str_tzrange2_inc_excl);
            IF NOT isempty(result_non_cont_part_a) THEN
                result := array_append(result, result_non_cont_part_a);
            END IF;
            IF NOT isempty(result_non_cont_part_b) THEN
                result := array_append(result, result_non_cont_part_b);
            END IF;
        ELSE
            IF (NOT isempty(rangeA - rangeB)) THEN
                result[1] := rangeA - rangeB;
            END IF;
        END IF;
    ELSE
        result[1] := rangeA;
    END IF;
    RETURN result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

