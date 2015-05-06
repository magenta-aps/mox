
--Subtract all of the tstzranges in the array from the first tstzrange given. 
create or replace function subtract_tstzrange_arr(rangeA tstzrange , rangeArr tstzrange[] )
returns tstzrange[] as
$$
DECLARE 
result tstzrange[];
temp_result tstzrange[];
rangeB tstzrange;
rangeA_leftover tstzrange;
BEGIN

result[1]:=rangeA;

FOREACH rangeB in array rangeArr
LOOP
	temp_result:=result;
	result:='{}';

	FOREACH rangeA_leftover in array temp_result
	LOOP
		result:=array_cat(result, subtract_tstzrange(rangeA_leftover,rangeB) );
	END LOOP;

END LOOP;

return result;

END;
$$ LANGUAGE plpgsql IMMUTABLE; 