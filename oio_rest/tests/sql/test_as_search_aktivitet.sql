-- SPDX-FileCopyrightText: 2016-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_search_aktivitet()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid1 uuid;
	new_uuid2 uuid;
	registrering aktivitetRegistreringType;
	registrering2 aktivitetRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaber Virkning;
	virkEgenskaber2 Virkning;
	virkAnsvarligklasse Virkning;
	virkResultatklasse1 Virkning;
	virkResultatklasse2 Virkning;
	virkDeltagerklasse1 Virkning;
	virkDeltagerklasse2 Virkning;
	virkUdfoerer1 Virkning;
	virkUdfoerer2 Virkning;
	virkPubliceret Virkning;
	virkStatus Virkning;
	aktivitetEgenskab aktivitetEgenskaberAttrType;
	aktivitetEgenskab2 aktivitetEgenskaberAttrType;
	aktivitetStatus aktivitetStatusTilsType;
	aktivitetPubliceret aktivitetPubliceretTilsType;
	aktivitetRelAnsvarligklasse aktivitetRelationType;
	aktivitetRelResultatklasse1 aktivitetRelationType;
	aktivitetRelResultatklasse2 aktivitetRelationType;
	aktivitetRelDeltagerklasse1 aktivitetRelationType;
	aktivitetRelDeltagerklasse2 aktivitetRelationType;
	aktivitetRelUdfoerer1 aktivitetRelationType;
	aktivitetRelUdfoerer2 aktivitetRelationType;

	uuidAnsvarligklasse uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	uuidResultatklasse1 uuid :='b7160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;


	--uuidResultatklasse2 uuid :='08533179-fedb-4aa7-8902-ab34a219eed9'::uuid;
	urnResultatklasse2 text:='urn:isbn:0451450523'::text;
	uuidDeltagerklasse1 uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09d'::uuid;
	uuidDeltagerklasse2 uuid :='28533179-fedb-4aa7-8902-ab34a219eed1'::uuid;
	uuidUdfoerer1  uuid :='884d99f6-568f-4772-8766-fac6d40f9cb0'::uuid;
	uuidUdfoerer2  uuid :='b6bb8e41-b47b-4420-b2a3-d1c38d86a1ad'::uuid;
	uuidRegistrering uuid :='1f368584-4c3e-4ba4-837b-da2b1eee37c9'::uuid;
	repraesentation_uuid uuid :='0e3ed41a-08f2-4967-8689-dce625f93029'::uuid;
	repraesentation_urn text :='isbn:97800232324'::text;

	actual_publiceret_virk virkning;
	actual_publiceret_value aktivitetStatusTils;
	actual_publiceret aktivitetStatusTilsType;
	actual_relationer aktivitetRelationType[];
	uuid_to_import uuid :='a1819cce-043b-447f-ba5e-92e6a75df918'::uuid;
	uuid_returned_from_import uuid;
	read_Aktivitet1 AktivitetType;
	expected_aktivitet1 AktivitetType;
	read_Aktivitet2 AktivitetType;
	expected_aktivitet2 AktivitetType;

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
	'[2015-05-12, 2015-06-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkEgenskaber2 :=	ROW (
	'[2015-06-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx90'
          ) :: Virkning
;

virkAnsvarligklasse :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkUdfoerer1 :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx342'
          ) :: Virkning
;

virkUdfoerer2 :=	ROW (
	'[2016-04-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx350'
          ) :: Virkning
;

virkResultatklasse1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkResultatklasse2 :=	ROW (
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

virkstatus := ROW (
	'[2016-12-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx20'
) :: Virkning
;

virkDeltagerklasse1 :=	ROW (
	'[2015-04-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx23'
          ) :: Virkning
;


virkDeltagerklasse2 :=	ROW (
	'[2015-06-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx12'
          ) :: Virkning
;

aktivitetRelAnsvarligklasse := ROW (
	'ansvarligklasse'::aktivitetRelationKode
	,virkAnsvarligklasse
	,uuidAnsvarligklasse
	,null
	,'Klasse'
	,567 --NOTICE: Should be replace in by import function
	,null --aktoerAttr
) :: aktivitetRelationType
;

aktivitetRelUdfoerer1 := ROW (
	'udfoerer'::aktivitetRelationKode
	,virkUdfoerer1
	,uuidUdfoerer1
	,null
	,'Person'
	,3 --NOTICE: Should be replace in by import function
	,ROW (
		 'valgfri'::AktivitetAktoerAttrObligatoriskKode,
  		'foreloebigt'::AktivitetAktoerAttrAccepteretKode,
  repraesentation_uuid,
  null 
	)::AktivitetAktoerAttr
) :: aktivitetRelationType
;


aktivitetRelUdfoerer2 := ROW (
	'udfoerer'::aktivitetRelationKode
	,virkUdfoerer2
	,uuidUdfoerer2
	,null
	,'Person'
	,3 --NOTICE: Should be replace in by import function
	,ROW (
		 'noedvendig'::AktivitetAktoerAttrObligatoriskKode,
  		'accepteret'::AktivitetAktoerAttrAccepteretKode,
  null,
  repraesentation_urn
	)::AktivitetAktoerAttr
) :: aktivitetRelationType
;


aktivitetRelResultatklasse1 := ROW (
	'resultatklasse'::aktivitetRelationKode,
		virkResultatklasse1,
	uuidResultatklasse1,
	null,
	'Klasse'
	,768 --NOTICE: Should be replace in by import function
	,null --aktoerAttr
) :: aktivitetRelationType
;



aktivitetRelResultatklasse2 := ROW (
	'resultatklasse'::aktivitetRelationKode,
		virkResultatklasse2,
	null,
	urnResultatklasse2,
	'Klasse'
	,800 --NOTICE: Should be replace in by import function
	,null --aktoerAttr
) :: aktivitetRelationType
;



aktivitetRelDeltagerklasse1 := ROW (
	'deltagerklasse'::aktivitetRelationKode,
		virkDeltagerklasse1,
	uuidDeltagerklasse1,
	null,
	'Klasse'
	,7268 --NOTICE: Should be replace in by import function
	,null --aktoerAttr
) :: aktivitetRelationType
;



aktivitetRelDeltagerklasse2 := ROW (
	'deltagerklasse'::aktivitetRelationKode,
		virkDeltagerklasse2,
	uuidDeltagerklasse2,
	null,
	'Klasse'
	,3 --NOTICE: Should be replace in by import function
	,null --aktoerAttr
) :: aktivitetRelationType
;



aktivitetStatus := ROW (
virkStatus,
'Aktiv'::AktivitetStatusTils
):: aktivitetStatusTilsType
;

aktivitetPubliceret := ROW (
virkPubliceret,
'Normal'::AktivitetPubliceretTils
)::aktivitetPubliceretTilsType;


aktivitetEgenskab := ROW (
 'aktivitet_1_brugervendtnoegle',
 'aktivitet_1_aktivitetnavn',
 'aktivitet_1_beskrivelse',
 '2017-02-25 17:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
  INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
 'aktivitet_1_formaal',
 'integrationsdata_1'
,virkEgenskaber
) :: aktivitetEgenskaberAttrType
;

aktivitetEgenskab2 := ROW (
 'aktivitet_2_brugervendtnoegle',
 'aktivitet_2_aktivitetnavn',
 'aktivitet_2_beskrivelse',
 '2016-04-20 10:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
'2017-02-27 12:00'::timestamptz, -- sluttidspunkt,
  INTERVAL '0000-00 01 04:00:01.0', --tidsforbrug
 'aktivitet_2_formaal',
 'integrationsdata_2'
,virkEgenskaber2
) :: aktivitetEgenskaberAttrType
;


registrering := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
	ARRAY[aktivitetStatus]::aktivitetStatusTilsType[],
	ARRAY[aktivitetPubliceret]::AktivitetPubliceretTilsType[],
ARRAY[aktivitetEgenskab]::aktivitetEgenskaberAttrType[],
ARRAY[aktivitetRelAnsvarligklasse,aktivitetRelResultatklasse1,aktivitetRelResultatklasse2,aktivitetRelDeltagerklasse1,aktivitetRelDeltagerklasse2,aktivitetRelUdfoerer1,aktivitetRelUdfoerer2]) :: aktivitetRegistreringType
;


--raise notice 'to be written aktivitet 1:%',to_json(registrering);

new_uuid1 := as_create_or_import_aktivitet(registrering);

RETURN NEXT ok(true,'No errors running as_create_or_import_aktivitet #1 ');


--raise notice 'expected_aktivitet1:%',to_json(expected_aktivitet1);


RETURN NEXT IS(
	read_Aktivitet1,
	expected_aktivitet1
	,'test create aktivitet #1'
);


/**************************************************/



registrering2 := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
	ARRAY[aktivitetStatus]::aktivitetStatusTilsType[],
	ARRAY[aktivitetPubliceret]::AktivitetPubliceretTilsType[],
ARRAY[aktivitetEgenskab,aktivitetEgenskab2]::aktivitetEgenskaberAttrType[],
ARRAY[	ROW (
				'ansvarligklasse'::aktivitetRelationKode
				,virkAnsvarligklasse
				,uuidAnsvarligklasse
				,null
				,'Klasse'
				,NULL 
				,null --ROW (null,null,null,null)::AktivitetAktoerAttr  --aktoerAttr
			) :: aktivitetRelationType
]::aktivitetRelationType[]
);

new_uuid2 := as_create_or_import_aktivitet(registrering2);

RETURN NEXT ok(true,'No errors running as_create_or_import_aktivitet #2 ');



/**************************************************/


expected_search_res_1:=array[new_uuid2]::uuid[];

actual_search_res_1:=as_search_aktivitet(null,null,
		ROW(
			null,
			null,-- AktivitetStatusTilsType[],
			null,-- AktivitetPubliceretTilsType[],
			ARRAY[ ROW (
 'aktivitet_2_brugervendtnoegle',
 null,--'aktivitet_2_aktivitetnavn',
 null,--'aktivitet_2_beskrivelse',
 null,--'2016-04-20 10:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
 null,--'2017-02-27 12:00'::timestamptz, -- sluttidspunkt,
 null,-- INTERVAL '0000-00 01 04:00:01.0', --tidsforbrug
 null,--'aktivitet_2_formaal'
 null,--'integrationsdata_2'
 null--virkEgenskaber2
) :: aktivitetEgenskaberAttrType ]::aktivitetEgenskaberAttrType[],
			null-- AktivitetRelationType[]
			)::aktivitetRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_1 @> actual_search_res_1 and actual_search_res_1 @>expected_search_res_1 and coalesce(array_length(expected_search_res_1,1),0)=coalesce(array_length(actual_search_res_1,1),0), 'search aktivitet #1.');


/**************************************************/

expected_search_res_2:=array[new_uuid1,new_uuid2]::uuid[];

actual_search_res_2:=as_search_aktivitet(null,null,
			ROW(
			null,
			null,-- AktivitetStatusTilsType[],
			null,-- AktivitetPubliceretTilsType[],
			ARRAY[ ROW (
 null,--'aktivitet_2_brugervendtnoegle',
 null,--'aktivitet_2_aktivitetnavn',
 null,--'aktivitet_2_beskrivelse',
 '2017-02-25 17:00'::timestamptz,--'2016-04-20 10:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
 null,--'2017-02-27 12:00'::timestamptz, -- sluttidspunkt,
 null,-- INTERVAL '0000-00 01 04:00:01.0', --tidsforbrug
 null,--'aktivitet_2_formaal'
 null,--'integrationsdata_2'
 null--virkEgenskaber2
) :: aktivitetEgenskaberAttrType ]::aktivitetEgenskaberAttrType[],
			null-- AktivitetRelationType[]
			)::aktivitetRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_2 @> actual_search_res_2 and actual_search_res_2 @>expected_search_res_2 and coalesce(array_length(expected_search_res_2,1),0)=coalesce(array_length(actual_search_res_2,1),0), 'search aktivitet #2.');

/**************************************************/
expected_search_res_3:=array[new_uuid2]::uuid[];

actual_search_res_3:=as_search_aktivitet(null,null,
		ROW(
			null,
			null,-- AktivitetStatusTilsType[],
			null,-- AktivitetPubliceretTilsType[],
			ARRAY[ ROW (
 null,--'aktivitet_3_brugervendtnoegle',
 null,--'aktivitet_3_aktivitetnavn',
 null,--'aktivitet_3_beskrivelse',
 null,--'2016-04-20 10:00'::timestamptz,  --'starttidspunkt_aktivitet_3' --text
 null,--'2017-02-27 12:00'::timestamptz, -- sluttidspunkt,
 INTERVAL '0000-00 01 04:00:01.0', --tidsforbrug
 null,--'aktivitet_3_formaal'
 null,--'integrationsdata_3'
 null--virkEgenskaber2
) :: aktivitetEgenskaberAttrType ]::aktivitetEgenskaberAttrType[],
			null-- AktivitetRelationType[]
			)::aktivitetRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_3 @> actual_search_res_3 and actual_search_res_3 @>expected_search_res_3 and coalesce(array_length(expected_search_res_3,1),0)=coalesce(array_length(actual_search_res_3,1),0), 'search aktivitet #3.');

/**************************************************/
expected_search_res_4:=array[new_uuid1]::uuid[];

actual_search_res_4:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null,--registreringObj
		null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,array[repraesentation_uuid]::uuid[]
		,null --anyurnArr
);

RETURN NEXT ok(expected_search_res_4 @> actual_search_res_4 and actual_search_res_4 @>expected_search_res_4 and coalesce(array_length(expected_search_res_4,1),0)=coalesce(array_length(actual_search_res_4,1),0), 'search aktivitet #4.');

/**************************************************/
expected_search_res_5:=array[new_uuid1]::uuid[];

actual_search_res_5:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null,--registreringObj
		null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,array[repraesentation_urn]::text[] --anyurnArr
);

RETURN NEXT ok(expected_search_res_5 @> actual_search_res_5 and actual_search_res_5 @>expected_search_res_5 and coalesce(array_length(expected_search_res_5,1),0)=coalesce(array_length(actual_search_res_5,1),0), 'search aktivitet #5.');


/**************************************************/
expected_search_res_6:=array[new_uuid2]::uuid[];

actual_search_res_6:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null,--registreringObj
		null --virkningSoeg	
		,null --maxResults
		,array['aktivitet_2_brugervendtnoegle']::text[] --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
);

RETURN NEXT ok(expected_search_res_6 @> actual_search_res_6 and actual_search_res_6 @>expected_search_res_6 and coalesce(array_length(expected_search_res_6,1),0)=coalesce(array_length(actual_search_res_6,1),0), 'search aktivitet #6.');


/**************************************************/
expected_search_res_7:=array[new_uuid1]::uuid[];

actual_search_res_7:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		ROW(
			null,
			null,-- AktivitetStatusTilsType[],
			null,-- AktivitetPubliceretTilsType[],
			null,
			ARRAY [
				ROW (
	'udfoerer'::aktivitetRelationKode
	,null--virkUdfoerer1
	,null--uuidUdfoerer1
	,null
	,null--'Person'
	,null--3 --NOTICE: Should be replace in by import function
	,ROW (
		 null,--'valgfri'::AktivitetAktoerAttrObligatoriskKode,
  		'foreloebigt'::AktivitetAktoerAttrAccepteretKode,
    null,--repraesentation_uuid,
  null 
	)::AktivitetAktoerAttr
) :: aktivitetRelationType
			]::AktivitetRelationType[]
							)::aktivitetRegistreringType
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
);

RETURN NEXT ok(expected_search_res_7 @> actual_search_res_7 and actual_search_res_7 @>expected_search_res_7 and coalesce(array_length(expected_search_res_7,1),0)=coalesce(array_length(actual_search_res_7,1),0), 'search aktivitet #7.');


/**************************************************/
expected_search_res_8:=array[]::uuid[];

actual_search_res_8:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		ROW(
			null,
			null,-- AktivitetStatusTilsType[],
			null,-- AktivitetPubliceretTilsType[],
			null,
			ARRAY [
				ROW (
	'udfoerer'::aktivitetRelationKode
	,null--virkUdfoerer1
	,null--uuidUdfoerer1
	,null
	,null--'Person'
	,null--3 --NOTICE: Should be replace in by import function
	,ROW (
		 'noedvendig'::AktivitetAktoerAttrObligatoriskKode, --'valgfri'::AktivitetAktoerAttrObligatoriskKode,
  		'foreloebigt'::AktivitetAktoerAttrAccepteretKode,
    null,--repraesentation_uuid,
  null 
	)::AktivitetAktoerAttr
) :: aktivitetRelationType
			]::AktivitetRelationType[]
							)::aktivitetRegistreringType
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
);

RETURN NEXT ok(expected_search_res_8 @> actual_search_res_8 and actual_search_res_8 @>expected_search_res_8 and coalesce(array_length(expected_search_res_8,1),0)=coalesce(array_length(actual_search_res_8,1),0), 'search aktivitet #8.');


/**************************************************/
expected_search_res_9:=array[new_uuid1]::uuid[];

actual_search_res_9:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		ROW(
			null,
			null,-- AktivitetStatusTilsType[],
			null,-- AktivitetPubliceretTilsType[],
			null,
			ARRAY [
				ROW (
	'udfoerer'::aktivitetRelationKode
	,null--virkUdfoerer1
	,null--uuidUdfoerer1
	,null
	,null--'Person'
	,null--3 --NOTICE: Should be replace in by import function
	,ROW (
		 null, --'valgfri'::AktivitetAktoerAttrObligatoriskKode,
  		null,
    repraesentation_uuid,--repraesentation_uuid,
  null 
	)::AktivitetAktoerAttr
) :: aktivitetRelationType
			]::AktivitetRelationType[]
							)::aktivitetRegistreringType
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
);

RETURN NEXT ok(expected_search_res_9 @> actual_search_res_9 and actual_search_res_9 @>expected_search_res_9 and coalesce(array_length(expected_search_res_9,1),0)=coalesce(array_length(actual_search_res_9,1),0), 'search aktivitet #9.');


/**************************************************/
expected_search_res_10:=array[]::uuid[];

actual_search_res_10:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		ROW(
			null,
			null,-- AktivitetStatusTilsType[],
			null,-- AktivitetPubliceretTilsType[],
			null,
			ARRAY [
				ROW (
	'udfoerer'::aktivitetRelationKode
	,null--virkUdfoerer1
	,null--uuidUdfoerer1
	,null
	,null--'Person'
	,null--3 --NOTICE: Should be replace in by import function
	,ROW (
		 null, --'valgfri'::AktivitetAktoerAttrObligatoriskKode,
  		null,
     uuidAnsvarligklasse,--repraesentation_uuid,
  null 
	)::AktivitetAktoerAttr
) :: aktivitetRelationType
			]::AktivitetRelationType[]
							)::aktivitetRegistreringType
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
);

RETURN NEXT ok(expected_search_res_10 @> actual_search_res_10 and actual_search_res_10 @>expected_search_res_10 and coalesce(array_length(expected_search_res_10,1),0)=coalesce(array_length(actual_search_res_10,1),0), 'search aktivitet #10.');

/**************************************************/
expected_search_res_11:=array[new_uuid1]::uuid[];

actual_search_res_11:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		ROW(
			null,
			null,-- AktivitetStatusTilsType[],
			null,-- AktivitetPubliceretTilsType[],
			null,
			ARRAY [
				ROW (
	'udfoerer'::aktivitetRelationKode
	,null--virkUdfoerer1
	,null--uuidUdfoerer1
	,null
	,null--'Person'
	,null--3 --NOTICE: Should be replace in by import function
	,ROW (
		 null, --'valgfri'::AktivitetAktoerAttrObligatoriskKode,
  		null,
     null,--repraesentation_uuid,
  repraesentation_urn 
	)::AktivitetAktoerAttr
) :: aktivitetRelationType
			]::AktivitetRelationType[]
							)::aktivitetRegistreringType
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
);

RETURN NEXT ok(expected_search_res_11 @> actual_search_res_11 and actual_search_res_11 @>expected_search_res_11 and coalesce(array_length(expected_search_res_11,1),0)=coalesce(array_length(actual_search_res_11,1),0), 'search aktivitet #11.');

/**************************************************/
expected_search_res_12:=array[new_uuid1,new_uuid2]::uuid[];

actual_search_res_12:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				'2016-04-01 00:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				null,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				null,--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
				null--,virkEgenskaber
				) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_12 @> actual_search_res_12 and actual_search_res_12 @>expected_search_res_12 and coalesce(array_length(expected_search_res_12,1),0)=coalesce(array_length(actual_search_res_12,1),0), 'search aktivitet #12.');

/**************************************************/

/**************************************************/
expected_search_res_13:=array[]::uuid[];

actual_search_res_13:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				'2018-01-01 00:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				null,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				null,--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
				null--,virkEgenskaber
				) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_13 @> actual_search_res_13 and actual_search_res_13 @>expected_search_res_13 and coalesce(array_length(expected_search_res_13,1),0)=coalesce(array_length(actual_search_res_13,1),0), 'search aktivitet #13.');

--raise notice 'actual_search_res_13:%',to_json(actual_search_res_13);
--raise notice 'expected_search_res_13:%',to_json(expected_search_res_13);

/**************************************************/

expected_search_res_14:=array[new_uuid1,new_uuid2]::uuid[];

actual_search_res_14:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				'2016-01-01 00:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				null,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				null,--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
						ROW (
			'[2015-06-01, 2015-06-01]' :: TSTZRANGE,
				null,
				null,
				null
				) :: Virkning
						) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_14 @> actual_search_res_14 and actual_search_res_14 @>expected_search_res_14 and coalesce(array_length(expected_search_res_14,1),0)=coalesce(array_length(actual_search_res_14,1),0), 'search aktivitet #14.');
/**************************************************/

/**************************************************/

expected_search_res_15:=array[new_uuid2]::uuid[];

actual_search_res_15:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				'2016-01-01 00:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				null,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				null,--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
						ROW (
			'[2015-06-10, 2015-06-10]' :: TSTZRANGE,
				null,
				null,
				null
				) :: Virkning
						) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_15 @> actual_search_res_15 and actual_search_res_15 @>expected_search_res_15 and coalesce(array_length(expected_search_res_15,1),0)=coalesce(array_length(actual_search_res_15,1),0), 'search aktivitet #15.');

/**************************************************/

/**************************************************/
expected_search_res_16:=array[new_uuid2]::uuid[];

actual_search_res_16:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				null,--'2018-01-01 00:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				'2017-02-27 09:00'::timestamptz,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				null,--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
				null--,virkEgenskaber
				) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_16 @> actual_search_res_16 and actual_search_res_16 @>expected_search_res_16 and coalesce(array_length(expected_search_res_16,1),0)=coalesce(array_length(actual_search_res_16,1),0), 'search aktivitet #16.');


/**************************************************/
expected_search_res_17:=array[new_uuid2,new_uuid1]::uuid[];

actual_search_res_17:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				null,--'2018-01-01 00:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				'2017-02-27 08:00'::timestamptz,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				null,--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
				null--,virkEgenskaber
				) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_17 @> actual_search_res_17 and actual_search_res_17 @>expected_search_res_17 and coalesce(array_length(expected_search_res_17,1),0)=coalesce(array_length(actual_search_res_17,1),0), 'search aktivitet #17.');


/**************************************************/
expected_search_res_18:=array[]::uuid[];

actual_search_res_18:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				null,--'2018-01-01 00:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				'2017-02-27 13:00'::timestamptz,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				null,--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
				null--,virkEgenskaber
				) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_18 @> actual_search_res_18 and actual_search_res_18 @>expected_search_res_18 and coalesce(array_length(expected_search_res_18,1),0)=coalesce(array_length(actual_search_res_18,1),0), 'search aktivitet #18.');

/**************************************************/
expected_search_res_19:=array[new_uuid1,new_uuid2]::uuid[];

actual_search_res_19:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				'2016-04-20 10:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				null,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				null,--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
				null--,virkEgenskaber
				) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_19 @> actual_search_res_19 and actual_search_res_19 @>expected_search_res_19 and coalesce(array_length(expected_search_res_19,1),0)=coalesce(array_length(actual_search_res_19,1),0), 'search aktivitet #19.');


/**************************************************/
expected_search_res_20:=array[new_uuid1,new_uuid2]::uuid[];

actual_search_res_20:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,null --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				null,--'2016-04-20 10:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				null,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				INTERVAL '0000-00 01 00:00:00.0',--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
				null--,virkEgenskaber
				) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_20 @> actual_search_res_20 and actual_search_res_20 @>expected_search_res_20 and coalesce(array_length(expected_search_res_20,1),0)=coalesce(array_length(actual_search_res_20,1),0), 'search aktivitet #20.');

/**************************************************/
expected_search_res_21:=array[]::uuid[];

actual_search_res_21:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,'[2015-06-10 , 2015-06-10]' :: TSTZRANGE --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				null,--'2016-04-20 10:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				null,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				INTERVAL '0000-00 02 00:00:00.0',--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
				null--,virkEgenskaber
				) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_21 @> actual_search_res_21 and actual_search_res_21 @>expected_search_res_21 and coalesce(array_length(expected_search_res_21,1),0)=coalesce(array_length(actual_search_res_21,1),0), 'search aktivitet #21.');

/**************************************************/
expected_search_res_22:=array[new_uuid2]::uuid[];

actual_search_res_22:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,'[2015-06-10 , 2015-06-10]' :: TSTZRANGE --virkningSoeg	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				null,--'2016-04-20 10:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				null,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				INTERVAL '0000-00 01 00:00:00.0',--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
				null--,virkEgenskaber
				) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]  --search_operator_greater_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null,
		,null --search_operator_less_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null

);

RETURN NEXT ok(expected_search_res_22 @> actual_search_res_22 and actual_search_res_22 @>expected_search_res_22 and coalesce(array_length(expected_search_res_22,1),0)=coalesce(array_length(actual_search_res_22,1),0), 'search aktivitet #22.');
/**************************************************/
expected_search_res_23:=array[new_uuid2]::uuid[];

actual_search_res_23:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,null	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,null --search_operator_greater_then_attr_egenskaber
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				null,--'2016-04-20 10:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				null,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				INTERVAL '0000-00 02 00:00:00.0',--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
				null--,virkEgenskaber
				) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]   --search_operator_less_then_attr_egenskaber

);

RETURN NEXT ok(expected_search_res_23 @> actual_search_res_23 and actual_search_res_23 @>expected_search_res_23 and coalesce(array_length(expected_search_res_23,1),0)=coalesce(array_length(actual_search_res_23,1),0), 'search aktivitet #23.');

/**************************************************/

expected_search_res_24:=array[]::uuid[];

actual_search_res_24:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,null	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,null --search_operator_greater_then_attr_egenskaber
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				null,--'2016-04-20 10:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				null,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				INTERVAL '0000-00 01 00:00:00.0',--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
				null--,virkEgenskaber
				) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]   --search_operator_less_then_attr_egenskaber

);

RETURN NEXT ok(expected_search_res_24 @> actual_search_res_24 and actual_search_res_24 @>expected_search_res_24 and coalesce(array_length(expected_search_res_24,1),0)=coalesce(array_length(actual_search_res_24,1),0), 'search aktivitet #24.');

/**************************************************/

expected_search_res_25:=array[new_uuid1,new_uuid2]::uuid[];

actual_search_res_25:=as_search_aktivitet(
		null,--firstResult
		null,--aktivitet_uuid
		null
		,null	
		,null --maxResults
		,null --anyAttrValueArr
		,null --anyuuidArr
		,null --array[repraesentation_urn]::text[] --anyurnArr
		,null --auth_criteria_arr AktivitetRegistreringType[]=null,
		,null --search_operator_greater_then_attr_egenskaber
		,ARRAY[
			ROW (
				null,--'aktivitet_1_brugervendtnoegle',
				null,--'aktivitet_1_aktivitetnavn',
				null,--'aktivitet_1_beskrivelse',
				null,--'2016-04-20 10:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
				null,--'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
				INTERVAL '0000-01 00 00:00:00.0',--INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
				null,--'aktivitet_1_formaal'
				null,--'integrationsdata_1'
				null--,virkEgenskaber
				) :: aktivitetEgenskaberAttrType
		]::AktivitetEgenskaberAttrType[]   --search_operator_less_then_attr_egenskaber

);

RETURN NEXT ok(expected_search_res_25 @> actual_search_res_25 and actual_search_res_25 @>expected_search_res_25 and coalesce(array_length(expected_search_res_25,1),0)=coalesce(array_length(actual_search_res_25,1),0), 'search aktivitet #25.');



--raise notice 'actual_search_res_19:%',to_json(actual_search_res_19);
--raise notice 'expected_search_res_19:%',to_json(expected_search_res_19);


/*
	firstResult int,--TOOD ??
	aktivitet_uuid uuid,
	registreringObj AktivitetRegistreringType,
	virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	maxResults int = 2147483647,
	anyAttrValueArr text[] = '{}'::text[],
	anyuuidArr	uuid[] = '{}'::uuid[],
	anyurnArr text[] = '{}'::text[],
	auth_criteria_arr AktivitetRegistreringType[]=null,
	search_operator_greater_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null,
	search_operator_less_then_attr_egenskaber AktivitetEgenskaberAttrType[]=null
*/

END;
$$;
