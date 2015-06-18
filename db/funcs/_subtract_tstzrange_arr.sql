-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--Subtract all of the tstzranges in the array from the first tstzrange given. 
create or replace function _subtract_tstzrange_arr(rangeA tstzrange , rangeArr tstzrange[] )
returns tstzrange[] as
$$
DECLARE 
result tstzrange[];
temp_result tstzrange[];
rangeB tstzrange;
rangeA_leftover tstzrange;
BEGIN

result[1]:=rangeA;

IF rangeArr IS NOT NULL THEN
	FOREACH rangeB in array rangeArr
	LOOP
		temp_result:=result;
		result:='{}';

		FOREACH rangeA_leftover in array temp_result
		LOOP
			result:=array_cat(result, _subtract_tstzrange(rangeA_leftover,rangeB) );
		END LOOP;

	END LOOP;
END IF;

return result;

END;
$$ LANGUAGE plpgsql IMMUTABLE; 