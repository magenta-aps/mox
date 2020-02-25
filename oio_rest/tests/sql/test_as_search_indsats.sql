-- SPDX-FileCopyrightText: 2016-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_search_indsats()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid1 uuid;
	new_uuid2 uuid;
	registrering indsatsRegistreringType;
	registrering2 indsatsRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaber Virkning;
	virkEgenskaber2 Virkning;
	virkIndsatsmodtager Virkning;
	virkIndsatssag1 Virkning;
	virkIndsatssag2 Virkning;
	virkIndsatsaktoer1 Virkning;
	virkIndsatsaktoer2 Virkning;
	virkPubliceret Virkning;
	virkFremdrift Virkning;
	indsatsEgenskab indsatsEgenskaberAttrType;
	indsatsEgenskab2 indsatsEgenskaberAttrType;
	indsatsFremdrift indsatsFremdriftTilsType;
	indsatsPubliceret indsatsPubliceretTilsType;
	indsatsRelIndsatsmodtager indsatsRelationType;
	indsatsRelIndsatssag1 indsatsRelationType;
	indsatsRelIndsatssag2 indsatsRelationType;
	indsatsRelIndsatsaktoer1 indsatsRelationType;
	indsatsRelIndsatsaktoer2 indsatsRelationType;
	
	uuidIndsatsmodtager uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	uuidIndsatssag1 uuid :='b7160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;


	--uuidIndsatssag2 uuid :='08533179-fedb-4aa7-8902-ab34a219eed9'::uuid;
	urnIndsatssag2 text:='urn:isbn:0451450523'::text;
	uuidIndsatsaktoer1 uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09d'::uuid;
	uuidIndsatsaktoer2 uuid :='28533179-fedb-4aa7-8902-ab34a219eed1'::uuid;
	uuidRegistrering uuid :='1f368584-4c3e-4ba4-837b-da2b1eee37c9'::uuid;
	actual_publiceret_virk virkning;
	actual_publiceret_value indsatsFremdriftTils;
	actual_publiceret indsatsFremdriftTilsType;
	actual_relationer indsatsRelationType[];
	uuid_to_import uuid :='a1819cce-043b-447f-ba5e-92e6a75df918'::uuid;
	uuid_returned_from_import uuid;
	read_Indsats1 IndsatsType;
	expected_indsats1 IndsatsType;

expected_search_res_1 uuid[];
	expected_search_res_2 uuid[];
	expected_search_res_3 uuid[];
	expected_search_res_4 uuid[];
	expected_search_res_5 uuid[];
	expected_search_res_6 uuid[];
	expected_search_res_7 uuid[];
	expected_search_res_8 uuid[];
	expected_search_res_9 uuid[];
	expected_search_res_10 uuid[];
	expected_search_res_11 uuid[];
	expected_search_res_12 uuid[];
	expected_search_res_13 uuid[];
	expected_search_res_14 uuid[];
	expected_search_res_15 uuid[];
	expected_search_res_16 uuid[];
	expected_search_res_17 uuid[];
	expected_search_res_18 uuid[];
	expected_search_res_19 uuid[];
	expected_search_res_20 uuid[];
	expected_search_res_21 uuid[];
	expected_search_res_22 uuid[];
	expected_search_res_23 uuid[];
	expected_search_res_24 uuid[];
	expected_search_res_25 uuid[];
	expected_search_res_26 uuid[];
	expected_search_res_27 uuid[];
	expected_search_res_28 uuid[];
	expected_search_res_29 uuid[];

	actual_search_res_1 uuid[];
	actual_search_res_2 uuid[];
	actual_search_res_3 uuid[];
	actual_search_res_4 uuid[];
	actual_search_res_5 uuid[];
	actual_search_res_6 uuid[];
	actual_search_res_7 uuid[];
	actual_search_res_8 uuid[];
	actual_search_res_9 uuid[];
	actual_search_res_10 uuid[];
	actual_search_res_11 uuid[];
	actual_search_res_12 uuid[];
	actual_search_res_13 uuid[];
	actual_search_res_14 uuid[];
	actual_search_res_15 uuid[];
	actual_search_res_16 uuid[];
	actual_search_res_17 uuid[];
	actual_search_res_18 uuid[];
	actual_search_res_19 uuid[];
	actual_search_res_20 uuid[];
	actual_search_res_21 uuid[];
	actual_search_res_22 uuid[];
	actual_search_res_23 uuid[];
	actual_search_res_24 uuid[];
	actual_search_res_25 uuid[];
	actual_search_res_26 uuid[];
	actual_search_res_27 uuid[];
	actual_search_res_28 uuid[];
	actual_search_res_29 uuid[];


BEGIN


virkEgenskaber :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkEgenskaber2 :=	ROW (
	'[2016-06-01, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx43'
          ) :: Virkning
;

virkIndsatsmodtager :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkIndsatssag1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkIndsatssag2 :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;

virkPubliceret := ROW (
	'[2015-05-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx10'
) :: Virkning
;

virkfremdrift := ROW (
	'[2016-12-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx20'
) :: Virkning
;

virkIndsatsaktoer1 :=	ROW (
	'[2015-04-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx23'
          ) :: Virkning
;


virkIndsatsaktoer2 :=	ROW (
	'[2015-06-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx12'
          ) :: Virkning
;

indsatsRelIndsatsmodtager := ROW (
	'indsatsmodtager'::indsatsRelationKode
	,virkIndsatsmodtager
	,uuidIndsatsmodtager
	,null
	,'Person'
	,567 --NOTICE: Should be replace in by import function
) :: indsatsRelationType
;


indsatsRelIndsatssag1 := ROW (
	'indsatssag'::indsatsRelationKode,
		virkIndsatssag1,
	uuidIndsatssag1,
	null,
	'Sag'
	,768 --NOTICE: Should be replace in by import function
) :: indsatsRelationType
;



indsatsRelIndsatssag2 := ROW (
	'indsatssag'::indsatsRelationKode,
		virkIndsatssag2,
	null,
	urnIndsatssag2,
	'Sag'
	,800 --NOTICE: Should be replace in by import function
) :: indsatsRelationType
;



indsatsRelIndsatsaktoer1 := ROW (
	'indsatsaktoer'::indsatsRelationKode,
		virkIndsatsaktoer1,
	uuidIndsatsaktoer1,
	null,
	'Person'
	,7268 --NOTICE: Should be replace in by import function
) :: indsatsRelationType
;



indsatsRelIndsatsaktoer2 := ROW (
	'indsatsaktoer'::indsatsRelationKode,
		virkIndsatsaktoer2,
	uuidIndsatsaktoer2,
	null,
	'Person'
	,3 --NOTICE: Should be replace in by import function
) :: indsatsRelationType
;



indsatsFremdrift := ROW (
virkFremdrift,
'Visiteret'::IndsatsFremdriftTils
):: indsatsFremdriftTilsType
;

indsatsPubliceret := ROW (
virkPubliceret,
'Normal'::IndsatsPubliceretTils
)::indsatsPubliceretTilsType;

indsatsEgenskab := ROW (
'brugervendtnoegle_indsats_1' --text, 
,'beskrivelse_indsats_faelles'-- text,
, '2017-01-20 08:00'::timestamptz  -- starttidspunkt,
, '2017-01-20 12:00'::timestamptz -- sluttidspunkt,
,'integrationsdata_1'-- text,
,virkEgenskaber
) :: indsatsEgenskaberAttrType
;


registrering := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
	ARRAY[indsatsPubliceret]::IndsatsPubliceretTilsType[],
ARRAY[indsatsFremdrift]::indsatsFremdriftTilsType[],
ARRAY[indsatsEgenskab]::indsatsEgenskaberAttrType[],
ARRAY[indsatsRelIndsatsmodtager,indsatsRelIndsatssag1,indsatsRelIndsatssag2,indsatsRelIndsatsaktoer1,indsatsRelIndsatsaktoer2]) :: indsatsRegistreringType
;


--raise notice 'to be written indsats 1:%',to_json(registrering);

new_uuid1 := as_create_or_import_indsats(registrering);

RETURN NEXT ok(true,'No errors running as_create_or_import_indsats #1');



/*********************************************/


indsatsEgenskab2 := ROW (
'brugervendtnoegle_indsats_2' --text, 
,'beskrivelse_indsats_faelles'-- text,
, '2017-01-25 09:00'::timestamptz  -- starttidspunkt,
, '2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,'integrationsdata_2'-- text,
,virkEgenskaber2
) :: indsatsEgenskaberAttrType
;



registrering2 := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 35') :: RegistreringBase
	,
	ARRAY[indsatsPubliceret]::IndsatsPubliceretTilsType[],
ARRAY[indsatsFremdrift]::indsatsFremdriftTilsType[],
ARRAY[indsatsEgenskab2]::indsatsEgenskaberAttrType[],
ARRAY[indsatsRelIndsatsmodtager,indsatsRelIndsatsaktoer1,indsatsRelIndsatsaktoer2]) :: indsatsRegistreringType
;


--raise notice 'to be written indsats 1:%',to_json(registrering);

new_uuid2 := as_create_or_import_indsats(registrering2);

RETURN NEXT ok(true,'No errors running as_create_or_import_indsats #2');


/*********************************************/

expected_search_res_1:=array[new_uuid2]::uuid[];

actual_search_res_1:=as_search_indsats(null,null,
		ROW(
			null,
			null,
			null,
			ARRAY[ ROW (
'brugervendtnoegle_indsats_2' --text, 
,null--'beskrivelse_indsats_2'-- text,
, null--'2017-01-25 09:00'::timestamptz  -- starttidspunkt,
, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType ]::IndsatsEgenskaberAttrType[],
			null-- AktivitetRelationType[]
			)::indsatsRegistreringType	
		,null
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --anyurnArr
		,null --auth_criteria_arr
		,null --search_operator_greater_than_or_equal_attr_egenskaber
		,null --search_operator_less_than_or_equal_attr_egenskaber
);

RETURN NEXT ok(expected_search_res_1 @> actual_search_res_1 and actual_search_res_1 @>expected_search_res_1 and coalesce(array_length(expected_search_res_1,1),0)=coalesce(array_length(actual_search_res_1,1),0), 'search indsats #1.');

/**************************************************/

expected_search_res_2:=array[new_uuid1,new_uuid2]::uuid[];

actual_search_res_2:=as_search_indsats(null,null,
			ROW(
			null,
			null,-- indsatsStatusTilsType[],
			null,-- indsatsPubliceretTilsType[],
			ARRAY[  ROW (
null --text, 
,'beskrivelse_indsats_faelles'-- text,
, null--'2017-01-25 09:00'::timestamptz  -- starttidspunkt,
, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType ]::indsatsEgenskaberAttrType[],
			null-- indsatsRelationType[]
			)::indsatsRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_2 @> actual_search_res_2 and actual_search_res_2 @>expected_search_res_2 and coalesce(array_length(expected_search_res_2,1),0)=coalesce(array_length(actual_search_res_2,1),0), 'search indsats #2.');


/**************************************************/
 
expected_search_res_3:=array[new_uuid2]::uuid[];

actual_search_res_3:=as_search_indsats(null,null,
		ROW(
			null,
			null,-- indsatsStatusTilsType[],
			null,-- indsatsPubliceretTilsType[],
			ARRAY[  ROW (
null --'brugervendtnoegle_indsats_2' --text, 
,null--'beskrivelse_indsats_2'-- text,
, null--'2017-01-25 09:00'::timestamptz  -- starttidspunkt,
, '2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType ]::indsatsEgenskaberAttrType[],
			null-- indsatsRelationType[]
			)::indsatsRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_3 @> actual_search_res_3 and actual_search_res_3 @>expected_search_res_3 and coalesce(array_length(expected_search_res_3,1),0)=coalesce(array_length(actual_search_res_3,1),0), 'search indsats #3.');

/**************************************************/


expected_search_res_4:=array[new_uuid1]::uuid[];

actual_search_res_4:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null,--registreringObj
		null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,array[uuidIndsatssag1]::uuid[]
		,null --anyurnArr
);

RETURN NEXT ok(expected_search_res_4 @> actual_search_res_4 and actual_search_res_4 @>expected_search_res_4 and coalesce(array_length(expected_search_res_4,1),0)=coalesce(array_length(actual_search_res_4,1),0), 'search indsats #4.');
/**************************************************/



/**************************************************/
expected_search_res_5:=array[new_uuid1]::uuid[];

actual_search_res_5:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null,--registreringObj
		null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,array[urnIndsatssag2]::text[] --anyurnArr
);

RETURN NEXT ok(expected_search_res_5 @> actual_search_res_5 and actual_search_res_5 @>expected_search_res_5 and coalesce(array_length(expected_search_res_5,1),0)=coalesce(array_length(actual_search_res_5,1),0), 'search indsats #5.');

/**************************************************/
expected_search_res_6:=array[new_uuid2]::uuid[];

actual_search_res_6:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null,--registreringObj
		null --virkningSoeg	
		,null --maxResults
		,array['brugervendtnoegle_indsats_2']::text[] --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
);

RETURN NEXT ok(expected_search_res_6 @> actual_search_res_6 and actual_search_res_6 @>expected_search_res_6 and coalesce(array_length(expected_search_res_6,1),0)=coalesce(array_length(actual_search_res_6,1),0), 'search indsats #6.');



/**************************************************/
expected_search_res_7:=array[new_uuid1,new_uuid2]::uuid[];

actual_search_res_7:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,ARRAY[
			 ROW (
null --text, 
,null--'beskrivelse_indsats_2'-- text,
, '2017-01-20 08:00'::timestamptz   -- starttidspunkt,
, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_7 @> actual_search_res_7 and actual_search_res_7 @>expected_search_res_7 and coalesce(array_length(expected_search_res_7,1),0)=coalesce(array_length(actual_search_res_7,1),0), 'search indsats #7.');

/**************************************************/


/**************************************************/
expected_search_res_8:=array[]::uuid[];

actual_search_res_8:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,ARRAY[
			 ROW (
null --'brugervendtnoegle_indsats_2' --text, 
,null--'beskrivelse_indsats_2'-- text,
, '2018-01-20 08:00'::timestamptz   -- starttidspunkt,
, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_8 @> actual_search_res_8 and actual_search_res_8 @>expected_search_res_8 and coalesce(array_length(expected_search_res_8,1),0)=coalesce(array_length(actual_search_res_8,1),0), 'search indsats #8.');

/**************************************************/
expected_search_res_9:=array[new_uuid2]::uuid[];

actual_search_res_9:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,ARRAY[
			 ROW (
null --'brugervendtnoegle_indsats_2' --text, 
,null--'beskrivelse_indsats_2'-- text,
, '2017-01-22 08:00'::timestamptz   -- starttidspunkt,
, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_9 @> actual_search_res_9 and actual_search_res_9 @>expected_search_res_9 and coalesce(array_length(expected_search_res_9,1),0)=coalesce(array_length(actual_search_res_9,1),0), 'search indsats #9.');

/**************************************************/
expected_search_res_10:=array[new_uuid2]::uuid[];

actual_search_res_10:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,ARRAY[
			 ROW (
null --'brugervendtnoegle_indsats_2' --text, 
,null--'beskrivelse_indsats_2'-- text,
, null --'2017-01-22 08:00'::timestamptz   -- starttidspunkt,
, '2017-04-20 18:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_10 @> actual_search_res_10 and actual_search_res_10 @>expected_search_res_10 and coalesce(array_length(expected_search_res_10,1),0)=coalesce(array_length(actual_search_res_10,1),0), 'search indsats #10.');

/**************************************************/
expected_search_res_11:=array[new_uuid2]::uuid[];

actual_search_res_11:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,ARRAY[
			 ROW (
null --'brugervendtnoegle_indsats_2' --text, 
,null--'beskrivelse_indsats_2'-- text,
, null --'2017-01-22 08:00'::timestamptz   -- starttidspunkt,
, '2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_11 @> actual_search_res_11 and actual_search_res_11 @>expected_search_res_11 and coalesce(array_length(expected_search_res_11,1),0)=coalesce(array_length(actual_search_res_11,1),0), 'search indsats #11.');


/**************************************************/
expected_search_res_12:=array[]::uuid[];

actual_search_res_12:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,ARRAY[
			 ROW (
null --'brugervendtnoegle_indsats_2' --text, 
,null--'beskrivelse_indsats_2'-- text,
, null --'2017-01-22 08:00'::timestamptz   -- starttidspunkt,
, '2017-06-01 12:01'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_12 @> actual_search_res_12 and actual_search_res_12 @>expected_search_res_12 and coalesce(array_length(expected_search_res_12,1),0)=coalesce(array_length(actual_search_res_12,1),0), 'search indsats #12.');


/**************************************************/
expected_search_res_13:=array[new_uuid1]::uuid[];

actual_search_res_13:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null
		,'[2016-01-01 , 2016-01-01]' :: TSTZRANGE --virkningSoeg		
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,ARRAY[
			 ROW (
null --'brugervendtnoegle_indsats_2' --text, 
,null--'beskrivelse_indsats_2'-- text,
, null --'2017-01-22 08:00'::timestamptz   -- starttidspunkt,
, '2017-01-20 08:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_13 @> actual_search_res_13 and actual_search_res_13 @>expected_search_res_13 and coalesce(array_length(expected_search_res_13,1),0)=coalesce(array_length(actual_search_res_13,1),0), 'search indsats #13.');

/**************************************************/
expected_search_res_14:=array[]::uuid[];

actual_search_res_14:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null
		,'[2014-01-01 , 2014-01-01]' :: TSTZRANGE --virkningSoeg		
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,ARRAY[
			 ROW (
null --'brugervendtnoegle_indsats_2' --text, 
,null--'beskrivelse_indsats_2'-- text,
, null --'2017-01-22 08:00'::timestamptz   -- starttidspunkt,
, '2017-01-20 08:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_14 @> actual_search_res_14 and actual_search_res_14 @>expected_search_res_14 and coalesce(array_length(expected_search_res_14,1),0)=coalesce(array_length(actual_search_res_14,1),0), 'search indsats #14.');

/**************************************************/
expected_search_res_15:=array[new_uuid2]::uuid[];

actual_search_res_15:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		ROW(
			null,
			null,-- indsatsStatusTilsType[],
			null,-- indsatsPubliceretTilsType[],
			ARRAY[  ROW (
			'brugervendtnoegle_indsats_2' --text, 
			,null--'beskrivelse_indsats_2'-- text,
			, null--'2017-01-25 09:00'::timestamptz  -- starttidspunkt,
			, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
			,null--integrationsdata2
			,null--virkEgenskaber2
			) :: indsatsEgenskaberAttrType ]::indsatsEgenskaberAttrType[],
						null-- indsatsRelationType[]
						)::indsatsRegistreringType	
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,ARRAY[
			 ROW (
null --text, 
,null--'beskrivelse_indsats_2'-- text,
, '2017-01-20 08:00'::timestamptz   -- starttidspunkt,
, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_15 @> actual_search_res_15 and actual_search_res_15 @>expected_search_res_15 and coalesce(array_length(expected_search_res_15,1),0)=coalesce(array_length(actual_search_res_15,1),0), 'search indsats #15.');


/**************************************************/


expected_search_res_16:=array[new_uuid2]::uuid[];

actual_search_res_16:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		ROW(
			null,
			null,-- indsatsStatusTilsType[],
			null,-- indsatsPubliceretTilsType[],
			ARRAY[  ROW (
			'brugervendtnoegle_indsats_2' --text, 
			,null--'beskrivelse_indsats_2'-- text,
			, null--'2017-01-25 09:00'::timestamptz  -- starttidspunkt,
			, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
			,null--integrationsdata2
			,null--virkEgenskaber2
			) :: indsatsEgenskaberAttrType ]::indsatsEgenskaberAttrType[],
						null-- indsatsRelationType[]
						)::indsatsRegistreringType	
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,null  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,ARRAY[
			 ROW (
null --text, 
,null--'beskrivelse_indsats_2'-- text,
, '2017-01-25 09:00'::timestamptz   -- starttidspunkt,
, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[] --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_16 @> actual_search_res_16 and actual_search_res_16 @>expected_search_res_16 and coalesce(array_length(expected_search_res_16,1),0)=coalesce(array_length(actual_search_res_16,1),0), 'search indsats #16.');


/**************************************************/

expected_search_res_17:=array[new_uuid2,new_uuid1]::uuid[];

actual_search_res_17:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		ROW(
			null,
			null,-- indsatsStatusTilsType[],
			null,-- indsatsPubliceretTilsType[],
			ARRAY[  ROW (
			null --'brugervendtnoegle_indsats_2' --text, 
			,'beskrivelse_indsats_faelles'-- text,
			, null--'2017-01-25 09:00'::timestamptz  -- starttidspunkt,
			, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
			,null--integrationsdata2
			,null--virkEgenskaber2
			) :: indsatsEgenskaberAttrType ]::indsatsEgenskaberAttrType[],
						null-- indsatsRelationType[]
						)::indsatsRegistreringType	
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,null  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,ARRAY[
			 ROW (
null --text, 
,null--'beskrivelse_indsats_2'-- text,
, '2017-01-25 09:00'::timestamptz   -- starttidspunkt,
, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[] --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_17 @> actual_search_res_17 and actual_search_res_17 @>expected_search_res_17 and coalesce(array_length(expected_search_res_17,1),0)=coalesce(array_length(actual_search_res_17,1),0), 'search indsats #17.');


/**************************************************/

/**************************************************/

expected_search_res_18:=array[new_uuid1]::uuid[];

actual_search_res_18:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		ROW(
			null,
			null,-- indsatsStatusTilsType[],
			null,-- indsatsPubliceretTilsType[],
			ARRAY[  ROW (
			null --'brugervendtnoegle_indsats_2' --text, 
			,'beskrivelse_indsats_faelles'-- text,
			, null--'2017-01-25 09:00'::timestamptz  -- starttidspunkt,
			, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
			,null--integrationsdata2
			,null--virkEgenskaber2
			) :: indsatsEgenskaberAttrType ]::indsatsEgenskaberAttrType[],
						null-- indsatsRelationType[]
						)::indsatsRegistreringType	
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,null  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,ARRAY[
			 ROW (
null --text, 
,null--'beskrivelse_indsats_2'-- text,
, '2017-01-25 08:00'::timestamptz   -- starttidspunkt,
, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[] --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_18 @> actual_search_res_18 and actual_search_res_18 @>expected_search_res_18 and coalesce(array_length(expected_search_res_18,1),0)=coalesce(array_length(actual_search_res_18,1),0), 'search indsats #18.');

/**************************************************/

expected_search_res_19:=array[]::uuid[];

actual_search_res_19:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		ROW(
			null,
			null,-- indsatsStatusTilsType[],
			null,-- indsatsPubliceretTilsType[],
			ARRAY[  ROW (
			'brugervendtnoegle_indsats_2' --text, 
			,null --'beskrivelse_indsats_faelles'-- text,
			, null--'2017-01-25 09:00'::timestamptz  -- starttidspunkt,
			, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
			,null--integrationsdata2
			,null--virkEgenskaber2
			) :: indsatsEgenskaberAttrType ]::indsatsEgenskaberAttrType[],
						null-- indsatsRelationType[]
						)::indsatsRegistreringType	
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,null  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,ARRAY[
			 ROW (
null --text, 
,null--'beskrivelse_indsats_2'-- text,
, '2017-01-25 08:00'::timestamptz   -- starttidspunkt,
, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[] --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_19 @> actual_search_res_19 and actual_search_res_19 @>expected_search_res_19 and coalesce(array_length(expected_search_res_19,1),0)=coalesce(array_length(actual_search_res_19,1),0), 'search indsats #19.');

/**************************************************/

expected_search_res_20:=array[new_uuid1]::uuid[];

actual_search_res_20:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null	
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,null  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,ARRAY[
			 ROW (
null --text, 
,null--'beskrivelse_indsats_2'-- text,
, '2017-01-25 09:00'::timestamptz   -- starttidspunkt,
, '2017-04-01 18:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[] --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_20 @> actual_search_res_20 and actual_search_res_20 @>expected_search_res_20 and coalesce(array_length(expected_search_res_20,1),0)=coalesce(array_length(actual_search_res_20,1),0), 'search indsats #20.');

/**************************************************/

expected_search_res_21:=array[new_uuid1,new_uuid2]::uuid[];

actual_search_res_21:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null	
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,null  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,ARRAY[
			 ROW (
null --text, 
,null--'beskrivelse_indsats_2'-- text,
, null -- starttidspunkt
, '2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[] --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_21 @> actual_search_res_21 and actual_search_res_21 @>expected_search_res_21 and coalesce(array_length(expected_search_res_21,1),0)=coalesce(array_length(actual_search_res_21,1),0), 'search indsats #21.');

/**************************************************/
expected_search_res_22:=array[new_uuid1]::uuid[];

actual_search_res_22:=as_search_indsats(
		null,--firstResult
		null,--indsats_uuid
		null	
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr indsatsRegistreringType[]=null,
		,null  --search_operator_greater_then_attr_egenskaber indsatsEgenskaberAttrType[]=null,
		,ARRAY[
			 ROW (
null --text, 
,null--'beskrivelse_indsats_2'-- text,
, null -- starttidspunkt
, '2017-06-01 11:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType
		]::indsatsEgenskaberAttrType[] --search_operator_less_then_attr_egenskaber indsatsEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_22 @> actual_search_res_22 and actual_search_res_22 @>expected_search_res_22 and coalesce(array_length(expected_search_res_22,1),0)=coalesce(array_length(actual_search_res_22,1),0), 'search indsats #22.');




END;
$$;
