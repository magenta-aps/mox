-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
,'beskrivelse_indsats_1'-- text,
, '2017-01-20 08:00'::timestamptz  -- starttidspunkt,
, '2017-01-20 12:00'::timestamptz -- sluttidspunkt,
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
,'beskrivelse_indsats_2'-- text,
, '2017-01-25 09:00'::timestamptz  -- starttidspunkt,
, '2017-06-01 12:00'::timestamptz -- sluttidspunkt,
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
			null,-- AktivitetStatusTilsType[],
			null,-- AktivitetPubliceretTilsType[],
			ARRAY[ ROW (
'brugervendtnoegle_indsats_2' --text, 
,null--'beskrivelse_indsats_2'-- text,
, null--'2017-01-25 09:00'::timestamptz  -- starttidspunkt,
, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
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


/*
read_Indsats1 := as_read_indsats(new_uuid1,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);
raise notice 'read_Indsats1:%',to_json(read_Indsats1);

expected_indsats1:=ROW(
		new_uuid1,
		ARRAY[
			ROW(
			(read_Indsats1.registrering[1]).registrering
			,ARRAY[indsatsPubliceret]::indsatsPubliceretTilsType[]
			,ARRAY[indsatsFremdrift]::indsatsFremdriftTilsType[]
			,ARRAY[indsatsEgenskab]::indsatsEgenskaberAttrType[]
			,ARRAY[
				ROW (
				'indsatsaktoer'::indsatsRelationKode,
					virkIndsatsaktoer2,
				uuidIndsatsaktoer2,
				null,
				'Person'
				,2 --NOTICE: Should be replace in by import function
			) :: indsatsRelationType
				,
				ROW (
					'indsatssag'::indsatsRelationKode,
						virkIndsatssag1,
					uuidIndsatssag1,
					null,
					'Sag'
					,1 --NOTICE: Was replaced
				) :: indsatsRelationType
				,
				ROW (
				'indsatsaktoer'::indsatsRelationKode,
					virkIndsatsaktoer1,
				uuidIndsatsaktoer1,
				null,
				'Person'
				,1 --NOTICE: Was replaced  by import function
			) :: indsatsRelationType
			,
				ROW (
				'indsatsmodtager'::indsatsRelationKode
				,virkIndsatsmodtager
				,uuidIndsatsmodtager
				,null
				,'Person'
				,NULL --NOTICE: Was replaced
			) :: indsatsRelationType
			,ROW (
				'indsatssag'::indsatsRelationKode,
					virkIndsatssag2,
				null,
				urnIndsatssag2,
				'Sag'
				,2 --NOTICE: Was replaced
			) :: indsatsRelationType

				]::IndsatsRelationType[]
			)::IndsatsRegistreringType
			]::IndsatsRegistreringType[]
		)::IndsatsType
;

--raise notice 'expected_indsats1:%',to_json(expected_indsats1);



RETURN NEXT IS(
	read_Indsats1,
	expected_indsats1
	,'test create indsats #1'
);


*/




END;
$$;