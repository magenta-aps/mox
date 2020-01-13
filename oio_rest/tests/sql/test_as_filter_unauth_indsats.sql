-- SPDX-FileCopyrightText: 2016-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_filter_unauth_indsats()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid1 uuid;
	new_uuid2 uuid;
	new_uuid3 uuid;
	registrering indsatsRegistreringType;
	registrering2 indsatsRegistreringType;
	registrering3 indsatsRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaber Virkning;
	virkEgenskaber2 Virkning;
	virkEgenskaber3 Virkning;
	virkIndsatsmodtager Virkning;
	virkIndsatsmodtager3 Virkning;
	virkIndsatssag1 Virkning;
	virkIndsatssag2 Virkning;
	virkIndsatsaktoer1 Virkning;
	virkIndsatsaktoer2 Virkning;
	virkPubliceret Virkning;
	virkPubliceret3 Virkning;
	virkFremdrift Virkning;
	virkFremdrift3 Virkning;
	indsatsEgenskab indsatsEgenskaberAttrType;
	indsatsEgenskab2 indsatsEgenskaberAttrType;
	indsatsEgenskab3 indsatsEgenskaberAttrType;
	indsatsFremdrift indsatsFremdriftTilsType;
	indsatsFremdrift3 indsatsFremdriftTilsType;
	indsatsPubliceret indsatsPubliceretTilsType;
	indsatsPubliceret3 indsatsPubliceretTilsType;
	indsatsRelIndsatsmodtager indsatsRelationType;
	indsatsRelIndsatsmodtager3 indsatsRelationType;
	indsatsRelIndsatssag1 indsatsRelationType;
	indsatsRelIndsatssag2 indsatsRelationType;
	indsatsRelIndsatsaktoer1 indsatsRelationType;
	indsatsRelIndsatsaktoer2 indsatsRelationType;
	
	uuidIndsatsmodtager uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	uuidIndsatssag1 uuid :='b7160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;
	uuidIndsatsmodtager3 uuid :='6cf639ec-82e9-45aa-8723-1dd0b42af37e'::uuid;

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
	read_Indsats2 IndsatsType;
	read_Indsats3 IndsatsType;
	expected_indsats1 IndsatsType;

expected_filter_res_1 uuid[];
	expected_filter_res_2 uuid[];
	expected_filter_res_3 uuid[];
	expected_filter_res_4 uuid[];
	expected_filter_res_5 uuid[];
	expected_filter_res_6 uuid[];
	expected_filter_res_7 uuid[];

	actual_filter_res_1 uuid[];
	actual_filter_res_2 uuid[];
	actual_filter_res_3 uuid[];
	actual_filter_res_4 uuid[];
	actual_filter_res_5 uuid[];
	actual_filter_res_6 uuid[];
	actual_filter_res_7 uuid[];
	


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
virkEgenskaber3 :=	ROW (
	'[2017-06-01, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx50'
          ) :: Virkning
;

indsatsEgenskab3 := ROW (
'brugervendtnoegle_indsats_3' --text, 
,'beskrivelse_indsats_faelles'-- text,
, '2017-02-25 09:00'::timestamptz  -- starttidspunkt,
, '2017-02-26 12:00'::timestamptz -- sluttidspunkt,
,'integrationsdata_3'-- text,
,virkEgenskaber3
) :: indsatsEgenskaberAttrType
;


virkIndsatsmodtager3 :=	ROW (
	'[2015-06-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx50'
          ) :: Virkning
;


indsatsRelIndsatsmodtager3 := ROW (
	'indsatsmodtager'::indsatsRelationKode
	,virkIndsatsmodtager3
	,uuidIndsatsmodtager3
	,null
	,'Person'
	,1 --NOTICE: Should be replace in by import function
) :: indsatsRelationType
;

virkPubliceret3 := ROW (
	'[2016-05-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx40'
) :: Virkning
;

virkfremdrift3 := ROW (
	'[2016-12-01, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx30'
) :: Virkning
;


indsatsFremdrift3 := ROW (
virkFremdrift3,
'Vurderet'::IndsatsFremdriftTils
):: indsatsFremdriftTilsType
;

indsatsPubliceret3 := ROW (
virkPubliceret3,
'IkkePubliceret'::IndsatsPubliceretTils
)::indsatsPubliceretTilsType;


registrering3 := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 35') :: RegistreringBase
	,
	ARRAY[indsatsPubliceret3]::IndsatsPubliceretTilsType[],
ARRAY[indsatsFremdrift3]::indsatsFremdriftTilsType[],
ARRAY[indsatsEgenskab3]::indsatsEgenskaberAttrType[],
ARRAY[indsatsRelIndsatsmodtager3]::indsatsRelationType[] ) :: indsatsRegistreringType
;


--raise notice 'to be written indsats 1:%',to_json(registrering);

new_uuid3 := as_create_or_import_indsats(registrering3);

RETURN NEXT ok(true,'No errors running as_create_or_import_indsats #3');



/*********************************************/

expected_filter_res_1:=array[new_uuid2]::uuid[];


actual_filter_res_1:=_as_filter_unauth_indsats(
	array[new_uuid1,new_uuid2,new_uuid3]::uuid[]
		,ARRAY[ ROW(
			null,
			null,
			null,
			ARRAY[ ROW (
'brugervendtnoegle_indsats_2' --text, 
,null--'beskrivelse_indsats_2'-- text,
, null--'2017-01-25 09:00'::timestamptz  -- starttidspunkt,
, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
, null
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType ]::IndsatsEgenskaberAttrType[],
			null-- AktivitetRelationType[]
		)::indsatsRegistreringType]::indsatsRegistreringType[]	
);

--read_Indsats1:=as_read_indsats(new_uuid1,null,null);
--read_Indsats2:=as_read_indsats(new_uuid2,null,null);
--read_Indsats3:=as_read_indsats(new_uuid3,null,null);

--raise notice 'indsats reg1 #1:%',to_json(actual_filter_res_1);

--raise notice 'returned uuids from filter #1:%',to_json(actual_filter_res_1);

RETURN NEXT ok(expected_filter_res_1 @> actual_filter_res_1 and actual_filter_res_1 @>expected_filter_res_1 and coalesce(array_length(expected_filter_res_1,1),0)=coalesce(array_length(actual_filter_res_1,1),0), 'unauth filter indsats #1.');

/**************************************************/

expected_filter_res_2:=array[new_uuid1]::uuid[];


actual_filter_res_2:=_as_filter_unauth_indsats(
	array[new_uuid1,new_uuid2,new_uuid3]::uuid[]
		,ARRAY[ ROW(
			null,
			null,
			null,
			ARRAY[ ROW (
null --text, 
,null--'beskrivelse_indsats_2'-- text,
, '2017-01-20 08:00'::timestamptz  -- starttidspunkt,
, null--'2017-06-01 12:00'::timestamptz -- sluttidspunkt,
,null--integrationsdata2
,null--virkEgenskaber2
) :: indsatsEgenskaberAttrType ]::IndsatsEgenskaberAttrType[],
			null-- AktivitetRelationType[]
		)::indsatsRegistreringType]::indsatsRegistreringType[]	
);

--read_Indsats1:=as_read_indsats(new_uuid1,null,null);
--read_Indsats2:=as_read_indsats(new_uuid2,null,null);
--read_Indsats3:=as_read_indsats(new_uuid3,null,null);

--raise notice 'indsats reg1 #1:%',to_json(actual_filter_res_2);

--raise notice 'returned uuids from filter #1:%',to_json(actual_filter_res_2);

RETURN NEXT ok(expected_filter_res_2 @> actual_filter_res_2 and actual_filter_res_2 @>expected_filter_res_2 and coalesce(array_length(expected_filter_res_2,1),0)=coalesce(array_length(actual_filter_res_2,1),0), 'unauth filter indsats #2.');
/**************************************************/

expected_filter_res_3:=array[new_uuid3]::uuid[];


actual_filter_res_3:=_as_filter_unauth_indsats(
	array[new_uuid1,new_uuid2,new_uuid3]::uuid[]
		,ARRAY[ ROW(
			null,
			 ARRAY [ROW (
			null,
			'IkkePubliceret'::IndsatsPubliceretTils
			 )::indsatsPubliceretTilsType]::indsatsPubliceretTilsType[],
			null,
			null,
			null-- AktivitetRelationType[]
		)::indsatsRegistreringType]::indsatsRegistreringType[]	
);

--read_Indsats1:=as_read_indsats(new_uuid1,null,null);
--read_Indsats2:=as_read_indsats(new_uuid2,null,null);
--read_Indsats3:=as_read_indsats(new_uuid3,null,null);

--raise notice 'indsats reg1 #1:%',to_json(actual_filter_res_3);

--raise notice 'returned uuids from filter #1:%',to_json(actual_filter_res_3);

RETURN NEXT ok(expected_filter_res_3 @> actual_filter_res_3 and actual_filter_res_3 @>expected_filter_res_3 and coalesce(array_length(expected_filter_res_3,1),0)=coalesce(array_length(actual_filter_res_3,1),0), 'unauth filter indsats #3.');

/**************************************************/

expected_filter_res_4:=array[new_uuid3]::uuid[];


actual_filter_res_4:=_as_filter_unauth_indsats(
	array[new_uuid1,new_uuid2,new_uuid3]::uuid[]
		,ARRAY[ ROW(
			null,
			null,
			array [ROW (
			null,
			'Vurderet'::IndsatsFremdriftTils
			):: indsatsFremdriftTilsType]::indsatsFremdriftTilsType[],
			null,
			null-- AktivitetRelationType[]
		)::indsatsRegistreringType]::indsatsRegistreringType[]	
);



--read_Indsats1:=as_read_indsats(new_uuid1,null,null);
--read_Indsats2:=as_read_indsats(new_uuid2,null,null);
--read_Indsats3:=as_read_indsats(new_uuid3,null,null);

--raise notice 'indsats reg1 #1:%',to_json(actual_filter_res_4);

--raise notice 'returned uuids from filter #1:%',to_json(actual_filter_res_4);

RETURN NEXT ok(expected_filter_res_4 @> actual_filter_res_4 and actual_filter_res_4 @>expected_filter_res_4 and coalesce(array_length(expected_filter_res_4,1),0)=coalesce(array_length(actual_filter_res_4,1),0), 'unauth filter indsats #4.');

/**************************************************/

expected_filter_res_5:=array[]::uuid[];


actual_filter_res_5:=_as_filter_unauth_indsats(
	array[new_uuid1,new_uuid2,new_uuid3]::uuid[]
		,ARRAY[ ROW(
			null,
			null,
			array [ROW (
			null,
			'Disponeret'::IndsatsFremdriftTils
			):: indsatsFremdriftTilsType]::indsatsFremdriftTilsType[],
			null,
			null-- AktivitetRelationType[]
		)::indsatsRegistreringType]::indsatsRegistreringType[]	
);



--read_Indsats1:=as_read_indsats(new_uuid1,null,null);
--read_Indsats2:=as_read_indsats(new_uuid2,null,null);
--read_Indsats3:=as_read_indsats(new_uuid3,null,null);

--raise notice 'indsats reg1 #1:%',to_json(actual_filter_res_5);

--raise notice 'returned uuids from filter #1:%',to_json(actual_filter_res_5);

RETURN NEXT ok(expected_filter_res_5 @> actual_filter_res_5 and actual_filter_res_5 @>expected_filter_res_5 and coalesce(array_length(expected_filter_res_5,1),0)=coalesce(array_length(actual_filter_res_5,1),0), 'unauth filter indsats #5.');

/**************************************************/

expected_filter_res_6:=array[new_uuid3]::uuid[];


actual_filter_res_6:=_as_filter_unauth_indsats(
	array[new_uuid1,new_uuid2,new_uuid3]::uuid[]
		,ARRAY[ ROW(
			null,
			null,
			null,
			null,
			array[
			 ROW (
				'indsatsmodtager'::indsatsRelationKode
					,null
				,uuidIndsatsmodtager3
					,null
					,null
					,null
				) :: indsatsRelationType
			]::indsatsRelationType[]
		)::indsatsRegistreringType]::indsatsRegistreringType[]	
);



--read_Indsats1:=as_read_indsats(new_uuid1,null,null);
--read_Indsats2:=as_read_indsats(new_uuid2,null,null);
--read_Indsats3:=as_read_indsats(new_uuid3,null,null);

--raise notice 'indsats reg1 #1:%',to_json(actual_filter_res_6);

--raise notice 'returned uuids from filter #1:%',to_json(actual_filter_res_6);

RETURN NEXT ok(expected_filter_res_6 @> actual_filter_res_6 and actual_filter_res_6 @>expected_filter_res_6 and coalesce(array_length(expected_filter_res_6,1),0)=coalesce(array_length(actual_filter_res_6,1),0), 'unauth filter indsats #6.');

/**************************************************/

expected_filter_res_7:=array[]::uuid[];


actual_filter_res_7:=_as_filter_unauth_indsats(
	array[new_uuid1,new_uuid2]::uuid[]
		,ARRAY[ ROW(
			null,
			null,
			null,
			null,
			array[
			 ROW (
				'indsatsmodtager'::indsatsRelationKode
					,null
				,uuidIndsatsmodtager3
					,null
					,null
					,null
				) :: indsatsRelationType
			]::indsatsRelationType[]
		)::indsatsRegistreringType]::indsatsRegistreringType[]	
);



--read_Indsats1:=as_read_indsats(new_uuid1,null,null);
--read_Indsats2:=as_read_indsats(new_uuid2,null,null);
--read_Indsats3:=as_read_indsats(new_uuid3,null,null);

--raise notice 'indsats reg1 #1:%',to_json(actual_filter_res_7);

--raise notice 'returned uuids from filter #1:%',to_json(actual_filter_res_7);

RETURN NEXT ok(expected_filter_res_7 @> actual_filter_res_7 and actual_filter_res_7 @>expected_filter_res_7 and coalesce(array_length(expected_filter_res_7,1),0)=coalesce(array_length(actual_filter_res_7,1),0), 'unauth filter indsats #7.');



END;
$$;
