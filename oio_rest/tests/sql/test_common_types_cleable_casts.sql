-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_common_types_cleable_casts()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
clearable_int1 ClearableInt;
clearable_int2 ClearableInt;
clearable_int3 ClearableInt;
clearable_int4 ClearableInt;

clearable_int5 ClearableInt;

clearable_date1 ClearableDate;
clearable_date2 ClearableDate;
clearable_date3 ClearableDate;
clearable_date4 ClearableDate;

clearable_date5 ClearableDate;

clearable_boolean1 ClearableBoolean;
clearable_boolean2 ClearableBoolean;
clearable_boolean3 ClearableBoolean;
clearable_boolean4 ClearableBoolean;
clearable_boolean5 ClearableBoolean;
clearable_boolean6 ClearableBoolean;
clearable_boolean7 ClearableBoolean;

clearable_Timestamptz1 ClearableTimestamptz;
clearable_Timestamptz2 ClearableTimestamptz;
clearable_Timestamptz3 ClearableTimestamptz;
clearable_Timestamptz4 ClearableTimestamptz;
clearable_Timestamptz5 ClearableTimestamptz;

clearable_interval1 ClearableInterval;
clearable_interval2 ClearableInterval;
clearable_interval3 ClearableInterval;
clearable_interval4 ClearableInterval;
clearable_interval5 ClearableInterval;

BEGIN

clearable_int1:= ROW (10,true)::ClearableInt;
clearable_int2:= ROW (20,false)::ClearableInt;
clearable_int3:= ROW (30,null)::ClearableInt;
clearable_int4:= ROW (null,null)::ClearableInt;

RETURN NEXT ok(clearable_int1=10,'ClearableInt->int cast test #1');
RETURN NEXT ok(clearable_int2=20,'ClearableInt->int cast test #2');
RETURN NEXT ok(clearable_int3=30,'ClearableInt->int cast test #3');
RETURN NEXT ok(clearable_int4 IS NULL,'ClearableInt->int cast test #4');
RETURN NEXT ok(clearable_int3>29,'ClearableInt->int cast test #5');
RETURN NEXT ok(clearable_int3<31,'ClearableInt->int cast test #6');

clearable_date1:= ROW ('2015-06-01'::date,true)::ClearableDate;
clearable_date2:= ROW ('2015-07-02'::date,false)::ClearableDate;
clearable_date3:= ROW ('2015-08-03'::date,null)::ClearableDate;
clearable_date4:= ROW (null,null)::ClearableDate;

RETURN NEXT ok(clearable_date1='2015-06-01'::date,'ClearableDate->date cast test #1');
RETURN NEXT ok(clearable_date2='2015-07-02'::date,'ClearableDate->date cast test #2');
RETURN NEXT ok(clearable_date3='2015-08-03'::date,'ClearableDate->date cast test #3');
RETURN NEXT ok(clearable_date4 IS NULL,'ClearableDate->date cast test #4');
RETURN NEXT ok(clearable_date3>'2015-08-02'::date,'ClearableDate->date cast test #5');
RETURN NEXT ok(clearable_date3<'2015-08-04'::date,'ClearableDate->date cast test #6');


clearable_boolean1:= ROW (true,true)::ClearableBoolean;
clearable_boolean2:= ROW (true,false)::ClearableBoolean;
clearable_boolean3:= ROW (false,false)::ClearableBoolean;
clearable_boolean4:= ROW (false,true)::ClearableBoolean;
clearable_boolean5:= ROW (true,NULL)::ClearableBoolean;
clearable_boolean6:= ROW (NULL,NULL)::ClearableBoolean;
clearable_boolean7:= ROW (NULL,true)::ClearableBoolean;

RETURN NEXT ok( clearable_boolean1=true,'ClearableBoolean->boolean cast test #1');
RETURN NEXT ok( clearable_boolean2=true,'ClearableBoolean->boolean cast test #2');
RETURN NEXT ok( clearable_boolean3=false,'ClearableBoolean->boolean cast test #3');
RETURN NEXT ok( clearable_boolean4=false,'ClearableBoolean->boolean cast test #4');
RETURN NEXT ok( clearable_boolean5=true,'ClearableBoolean->boolean cast test #5');
RETURN NEXT ok( clearable_boolean6 IS NULL,'ClearableBoolean->boolean cast test #6');
RETURN NEXT ok( NOT (clearable_boolean7 IS NULL),'ClearableBoolean->boolean cast test #7');

clearable_timestamptz1:= ROW ('2015-06-01 14:10'::timestamptz,true)::ClearableTimestamptz;
clearable_timestamptz2:= ROW ('2015-07-02 08:10'::timestamptz,false)::ClearableTimestamptz;
clearable_timestamptz3:= ROW ('2015-08-03 09:00'::timestamptz,null)::ClearableTimestamptz;
clearable_timestamptz4:= ROW (null,null)::ClearableDate;

RETURN NEXT ok(clearable_timestamptz1='2015-06-01 14:10'::timestamptz,'ClearableTimestamptz->timestamptz cast test #1');
RETURN NEXT ok(clearable_timestamptz2='2015-07-02 08:10'::timestamptz,'ClearableTimestamptz->timestamptz cast test #2');
RETURN NEXT ok(clearable_timestamptz3='2015-08-03 09:00'::timestamptz,'ClearableTimestamptz->timestamptz cast test #3');
RETURN NEXT ok(clearable_timestamptz4 IS NULL,'ClearableTimestamptz->timestamptz cast test #4');
RETURN NEXT ok(clearable_timestamptz3>'2015-08-02'::timestamptz,'ClearableTimestamptz->timestamptz cast test #5');
RETURN NEXT ok(clearable_timestamptz3<'2015-08-04'::timestamptz,'ClearableTimestamptz->timestamptz cast test #6');

clearable_interval1:= ROW ('0001-00 03 00:00:02.0'::interval(0),true)::ClearableInterval;
clearable_interval2:= ROW ('0002-00 00 00:00:00.0'::interval(0),false)::ClearableInterval;
clearable_interval3:= ROW ('0001-02 04 00:00:00.0'::interval(0),null)::ClearableInterval;
clearable_interval4:= ROW (null,null)::ClearableInterval;

RETURN NEXT ok(clearable_Interval1='0001-00 03 00:00:02.0'::interval(0),'ClearableInterval->Interval cast test #1');
RETURN NEXT ok(clearable_Interval2='0002-00 00 00:00:00.0'::interval(0),'ClearableInterval->Interval cast test #2');
RETURN NEXT ok(clearable_Interval3='0001-02 04 00:00:00.0'::interval(0),'ClearableInterval->Interval cast test #3');
RETURN NEXT ok(clearable_Interval4 IS NULL,'ClearableInterval->Interval cast test #4');
RETURN NEXT ok(clearable_Interval3>'0000-11 04 00:00:00.0'::Interval(0),'ClearableInterval->Interval cast test #5');
RETURN NEXT ok(clearable_Interval3<'0001-02 05 00:00:00.0'::Interval(0),'ClearableInterval->Interval cast test #6');
/**/

RETURN NEXT ok( (20::ClearableInt).value=20 and (20::ClearableInt).cleared is null ,'int->ClearableInt test #1');
RETURN NEXT ok(  (('2015-08-20'::date)::ClearableDate).value='2015-08-20'::date and (('2015-08-20'::date)::ClearableDate).cleared is null ,'date->ClearableDate test #1');
RETURN NEXT ok( (false::ClearableBoolean).value=false and (false::ClearableBoolean).cleared is null ,'boolean->ClearableBoolean test #1');
RETURN NEXT ok( (true::ClearableBoolean).value=true and (false::ClearableBoolean).cleared is null ,'boolean->ClearableBoolean test #2');

/**/

clearable_int5:=(''::text)::ClearableInt;
RETURN NEXT ok(clearable_int5.value IS NULL AND clearable_int5.cleared=true,'text->ClearableInt #1');
RETURN NEXT ok( (null::text)::ClearableInt IS NULL, 'text->ClearableInt #2');

BEGIN 
clearable_int5:=('test'::text)::ClearableInt;
	RETURN NEXT ok(false,'text->ClearableInt #3 DOES NOT throw exception as it should');
EXCEPTION  WHEN data_exception THEN
	RETURN NEXT ok(true,'text->ClearableInt #3 (throws exception as it should');
END;

/**/

clearable_date5:=(''::text)::ClearableDate;
RETURN NEXT ok(clearable_date5.value IS NULL AND clearable_date5.cleared=true,'text->ClearableDate #1');
RETURN NEXT ok( (null::text)::ClearableDate IS NULL, 'text->ClearableDate #2');

BEGIN 
clearable_date5:=('test'::text)::ClearableDate;
	RETURN NEXT ok(false,'text->ClearableDate #3 DOES NOT throw exception as it should');
EXCEPTION  WHEN data_exception THEN
	RETURN NEXT ok(true,'text->ClearableDate #3 (throws exception as it should');
END;

/**/

clearable_boolean5:=(''::text)::ClearableBoolean;
RETURN NEXT ok(clearable_boolean5.value IS NULL AND clearable_boolean5.cleared=true,'text->ClearableBoolean #1');
RETURN NEXT ok( (null::text)::ClearableBoolean IS NULL, 'text->ClearableBoolean #2');

BEGIN 
clearable_boolean5:=('test'::text)::ClearableBoolean;
	RETURN NEXT ok(false,'text->ClearableBoolean #3 DOES NOT throw exception as it should');
EXCEPTION  WHEN data_exception THEN
	RETURN NEXT ok(true,'text->ClearableBoolean #3 (throws exception as it should');
END;

/**/

clearable_Timestamptz5:=(''::text)::ClearableTimestamptz;
RETURN NEXT ok(clearable_Timestamptz5.value IS NULL AND clearable_Timestamptz5.cleared=true,'text->ClearableTimestamptz #1');
RETURN NEXT ok( (null::text)::ClearableTimestamptz IS NULL, 'text->ClearableTimestamptz #2');

BEGIN 
clearable_Timestamptz5:=('test'::text)::ClearableTimestamptz;
	RETURN NEXT ok(false,'text->ClearableTimestamptz #3 DOES NOT throw exception as it should');
EXCEPTION  WHEN data_exception THEN
	RETURN NEXT ok(true,'text->ClearableTimestamptz #3 (throws exception as it should');
END;

/**/

clearable_Interval5:=(''::text)::ClearableInterval;
RETURN NEXT ok(clearable_Interval5.value IS NULL AND clearable_Interval5.cleared=true,'text->ClearableInterval #1');
RETURN NEXT ok( (null::text)::ClearableInterval IS NULL, 'text->ClearableInterval #2');

BEGIN 
clearable_Interval5:=('test'::text)::ClearableInterval;
	RETURN NEXT ok(false,'text->ClearableInterval #3 DOES NOT throw exception as it should');
EXCEPTION  WHEN data_exception THEN
	RETURN NEXT ok(true,'text->ClearableInterval #3 (throws exception as it should');
END;

/**/



END;
$$;