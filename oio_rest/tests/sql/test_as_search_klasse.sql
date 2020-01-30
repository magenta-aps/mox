-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_search_klasse()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid_A uuid;
	registrering_A KlasseRegistreringType;
	actual_registrering_A registreringBase;
	virkEgenskaber_A Virkning;
	virkAnsvarlig_A Virkning;
	virkRedaktoer1_A Virkning;
	virkRedaktoer2_A Virkning;
	virkPubliceret_A Virkning;
	klasseEgenskab_A KlasseEgenskaberAttrType;
	klassePubliceret_A KlassePubliceretTilsType;
	klasseRelAnsvarlig_A KlasseRelationType;
	klasseRelRedaktoer1_A KlasseRelationType;
	klasseRelRedaktoer2_A KlasseRelationType;
	klasseRelSideordnede3_A KlasseRelationType;
	uuidAnsvarlig_A uuid :=uuid_generate_v4();
	uuidRedaktoer1_A uuid :=uuid_generate_v4();
	uuidRedaktoer2_A uuid :=uuid_generate_v4();

	uuidregistrering_AB uuid :=uuid_generate_v4();
	klasseEgenskabA_Soegeord1 KlasseSoegeordType;
	klasseEgenskabA_Soegeord2 KlasseSoegeordType;

	new_uuid_B uuid;
	registrering_B KlasseRegistreringType;
	actual_registrering_B registreringBase;
	virkEgenskaber_B Virkning;
	virkAnsvarlig_B Virkning;
	virkRedaktoer1_B Virkning;
	virkRedaktoer2_B Virkning;
	virkPubliceret_B Virkning;
	virkpubliceret2_b Virkning;
	klasseEgenskab_B KlasseEgenskaberAttrType;
	klassePubliceret_B KlassePubliceretTilsType;
	klassePubliceret_B2 KlassePubliceretTilsType;
	klasseRelAnsvarlig_B KlasseRelationType;
	klasseRelRedaktoer1_B KlasseRelationType;
	klasseRelRedaktoer2_B KlasseRelationType;
	klasseRelSideordnede3_B KlasseRelationType;
	uuidAnsvarlig_B uuid :=uuid_generate_v4();
	uuidRedaktoer1_B uuid :=uuid_generate_v4();
	uuidRedaktoer2_B uuid :=uuid_generate_v4();
	
	klasseEgenskabB_Soegeord1 KlasseSoegeordType;
	klasseEgenskabB_Soegeord2 KlasseSoegeordType;
	klasseEgenskabB_Soegeord3 KlasseSoegeordType;
	klasseEgenskabB_Soegeord4 KlasseSoegeordType;


	uuidSideordnede_AB uuid :=uuid_generate_v4();
	virkSideordnede_AB_A Virkning;
	virkSideordnede_AB_B Virkning;

	new_uuid_C uuid;
	registrering_C KlasseRegistreringType;
	actual_registrering_C registreringBase;
	virkEgenskaber_C Virkning;
	virkAnsvarlig_C Virkning;
	virkRedaktoer1_C Virkning;
	virkRedaktoer2_C Virkning;
	virkPubliceret_C Virkning;
	virkpubliceret2_C Virkning;
	klasseEgenskab_C KlasseEgenskaberAttrType;
	klassePubliceret_C KlassePubliceretTilsType;
	klassePubliceret_C2 KlassePubliceretTilsType;
	klasseRelAnsvarlig_C KlasseRelationType;
	klasseRelRedaktoer1_C KlasseRelationType;
	klasseRelRedaktoer2_C KlasseRelationType;
	uuidAnsvarlig_C uuid :=uuid_generate_v4();
	uuidRedaktoer1_C uuid :=uuid_generate_v4();
	uuidRedaktoer2_C uuid :=uuid_generate_v4();
	uuidregistrering_C uuid :=uuid_generate_v4();


	search_result1 uuid[];
	search_result1A uuid[];
	search_result2 uuid[];
	search_result2A uuid[];
	search_result3 uuid[];
	search_result3A uuid[];
	search_result4 uuid[];
	search_result5 uuid[];
	search_result6 uuid[];
	search_result7 uuid[];
	search_result8 uuid[];
	search_result9 uuid[];
	search_result10 uuid[];
	search_result11 uuid[];
	search_result12 uuid[];
	search_result13 uuid[];
	search_result14 uuid[];
	search_result15 uuid[];
	search_result16 uuid[];
	search_result17 uuid[];
	search_result18 uuid[];
	search_result19 uuid[];
	search_result20 uuid[];
	search_result21 uuid[];
	search_result22 uuid[];
	search_result23 uuid[];
	search_result24 uuid[];
	search_result25 uuid[];
	search_result26 uuid[];
	search_result27 uuid[];
	search_result28 uuid[];
	search_result29 uuid[];
	search_result30 uuid[];
	search_result31 uuid[];
	search_result32 uuid[];
	search_result33 uuid[];
	search_result34 uuid[];
	search_result35 uuid[];
	search_result36 uuid[];
	search_result37 uuid[];
	search_result38 uuid[];
	search_result39 uuid[];
	search_result40 uuid[];
	search_result41 uuid[];
	search_result42 uuid[];
	search_result43 uuid[];
	search_result44 uuid[];
	search_result45 uuid[];
	search_result46 uuid[];
	search_result47 uuid[];
	search_result48 uuid[];
	search_result49 uuid[];

	search_result200 uuid[];

	expected_result2 uuid[];
	expected_result2A uuid[];
	expected_result3A uuid[];
	expected_result4 uuid[];
	expected_result8 uuid[];
	expected_result9 uuid[];
	expected_result10 uuid[];
	expected_result11 uuid[];
	expected_result12 uuid[];
	expected_result13 uuid[];
	expected_result14 uuid[];
	expected_result15 uuid[];
	expected_result16 uuid[];
	expected_result17 uuid[];
	expected_result18 uuid[];
	expected_result19 uuid[];
	expected_result20 uuid[];
	expected_result21 uuid[];
	expected_result22 uuid[];
	expected_result23 uuid[];
	expected_result24 uuid[];
	expected_result25 uuid[];
	expected_result26 uuid[];
	expected_result27 uuid[];
	expected_result28 uuid[];
	expected_result29 uuid[];
	expected_result30 uuid[];
	expected_result31 uuid[];
	expected_result32 uuid[];
	expected_result33 uuid[];
	expected_result34 uuid[];
	expected_result35 uuid[];
	expected_result36 uuid[];
	expected_result37 uuid[];
	expected_result38 uuid[];
	expected_result39 uuid[];
	expected_result40 uuid[];
	expected_result41 uuid[];
	expected_result42 uuid[];
	expected_result43 uuid[];
	expected_result44 uuid[];
	expected_result45 uuid[];
	expected_result46 uuid[];
	expected_result47 uuid[];
	expected_result48 uuid[];
	expected_result49 uuid[];

	expected_result200 uuid[];

	search_registrering_3 KlasseRegistreringType;
	search_registrering_3A KlasseRegistreringType;
	search_registrering_4 KlasseRegistreringType;
	search_registrering_5 KlasseRegistreringType;
	search_registrering_6 KlasseRegistreringType;
	search_registrering_7 KlasseRegistreringType;
	search_registrering_8 KlasseRegistreringType;
	search_registrering_9 KlasseRegistreringType;
	search_registrering_10 KlasseRegistreringType;
	search_registrering_11 KlasseRegistreringType;
	search_registrering_12 KlasseRegistreringType;
	search_registrering_13 KlasseRegistreringType;
	search_registrering_14 KlasseRegistreringType;
	search_registrering_15 KlasseRegistreringType;
	search_registrering_16 KlasseRegistreringType;
	search_registrering_17 KlasseRegistreringType;
	search_registrering_18 KlasseRegistreringType;
	search_registrering_19 KlasseRegistreringType;
	search_registrering_20 KlasseRegistreringType;
	search_registrering_21 KlasseRegistreringType;
	search_registrering_22 KlasseRegistreringType;
	search_registrering_23 KlasseRegistreringType;
	search_registrering_24 KlasseRegistreringType;
	search_registrering_25 KlasseRegistreringType;
	search_registrering_26 KlasseRegistreringType;
	search_registrering_27 KlasseRegistreringType;
	search_registrering_28 KlasseRegistreringType;
	search_registrering_29 KlasseRegistreringType;
	search_registrering_30 KlasseRegistreringType;
	search_registrering_31 KlasseRegistreringType;
	search_registrering_32 KlasseRegistreringType;
	search_registrering_33 KlasseRegistreringType;
	search_registrering_34 KlasseRegistreringType;
	search_registrering_35 KlasseRegistreringType;
	search_registrering_36 KlasseRegistreringType;
	search_registrering_37 KlasseRegistreringType;
	search_registrering_38 KlasseRegistreringType;
	search_registrering_39 KlasseRegistreringType;
	search_registrering_40 KlasseRegistreringType;
	search_registrering_41 KlasseRegistreringType;
	search_registrering_42 KlasseRegistreringType;
	search_registrering_43 KlasseRegistreringType;
	search_registrering_44 KlasseRegistreringType;
	search_registrering_45 KlasseRegistreringType;
	search_registrering_46 KlasseRegistreringType;
	search_registrering_47 KlasseRegistreringType;
	search_registrering_48 KlasseRegistreringType;
	search_registrering_49 KlasseRegistreringType;

	search_registrering_200 KlasseRegistreringType;

	update_reg_id bigint;
	rows_affected int;
	read_Klasse1 KlasseType;
	read_Klasse2 KlasseType;
	read_Klasse3 KlasseType;
BEGIN


virkEgenskaber_A :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkAnsvarlig_A :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkRedaktoer1_A :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkRedaktoer2_A :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;


virkPubliceret_A := ROW (
	'[2015-05-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx10'
) :: Virkning
;

virkSideordnede_AB_A := ROW (
	'[2015-03-20, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx10'
) :: Virkning
;

klasseRelAnsvarlig_A := ROW (
	'ansvarlig'::KlasseRelationKode,
		virkAnsvarlig_A,
	uuidAnsvarlig_A,
	null,
	null
) :: KlasseRelationType
;


klasseRelRedaktoer1_A := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer1_A,
	uuidRedaktoer1_A,
	null,
	null
) :: KlasseRelationType
;



klasseRelRedaktoer2_A := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer2_A,
	uuidRedaktoer2_A,
	null,
	null
) :: KlasseRelationType
;

klasseRelSideordnede3_A := ROW (
	'sideordnede'::KlasseRelationKode,
		virkSideordnede_AB_A,
	uuidSideordnede_AB,
	null,
	null
) :: KlasseRelationType
;


klassePubliceret_A := ROW (
virkPubliceret_A,
'Publiceret'
):: KlassePubliceretTilsType
;

klasseEgenskabA_Soegeord1 := ROW(
'soegeordidentifikator_klasseEgenskabA_Soegeord1',
'beskrivelse_klasseEgenskabA_Soegeord1',
'faellessogeord2'
)::KlasseSoegeordType
;
klasseEgenskabA_Soegeord2 := ROW(
'soegeordidentifikator_klasseEgenskabA_Soegeord2',
'beskrivelse_klasseEgenskabA_Soegeord2',
'faellessogeord1'
)::KlasseSoegeordType
;

klasseEgenskab_A := ROW (
'brugervendt_noegle_A',
   'klassebeskrivelse_A',
   'eksempel_faelles',
	'omfang_AB',
   'titel_A',
   'retskilde_A',
   NULL,--'aendringsnotat_text1',
   'integrationsdata_A',
   ARRAY[klasseEgenskabA_Soegeord1,klasseEgenskabA_Soegeord2]::KlasseSoegeordType[], 
   virkEgenskaber_A
) :: KlasseEgenskaberAttrType
;

registrering_A := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidregistrering_AB,
	'Test Note 4') :: registreringBase
	,
ARRAY[klassePubliceret_A]::KlassePubliceretTilsType[],
ARRAY[klasseEgenskab_A]::KlasseEgenskaberAttrType[],
ARRAY[klasseRelAnsvarlig_A,klasseRelRedaktoer1_A,klasseRelRedaktoer2_A,klasseRelSideordnede3_A]
) :: KlasseRegistreringType
;

new_uuid_A := as_create_or_import_klasse(registrering_A);



--*******************


virkEgenskaber_B :=	ROW (
	'[2015-04-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkAnsvarlig_B :=	ROW (
	'[2015-04-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkRedaktoer1_B :=	ROW (
	'[2015-04-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkRedaktoer2_B :=	ROW (
	'[2015-04-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;

virkSideordnede_AB_B := ROW (
	'[2014-01-20, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx11'
) :: Virkning
;

virkPubliceret_B := ROW (
	'[2015-05-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx10'
) :: Virkning
;

virkPubliceret2_B := ROW (
	'[2014-05-18, 2015-05-18)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx143'
) :: Virkning
;


klasseRelAnsvarlig_B := ROW (
	'ansvarlig'::KlasseRelationKode,
		virkAnsvarlig_B,
	uuidAnsvarlig_B,
	null,
	null
) :: KlasseRelationType
;


klasseRelRedaktoer1_B := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer1_B,
	uuidRedaktoer1_B,
	null,
	null
) :: KlasseRelationType
;



klasseRelRedaktoer2_B := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer2_B,
	uuidRedaktoer2_B,
	null,
	null
) :: KlasseRelationType
;

klasseRelSideordnede3_B := ROW (
	'sideordnede'::KlasseRelationKode,
		virkSideordnede_AB_B,
	uuidSideordnede_AB,
	null,
	null
) :: KlasseRelationType
;


klassePubliceret_B := ROW (
virkPubliceret_B,
'Publiceret'
):: KlassePubliceretTilsType
;

klassePubliceret_B2 := ROW (
virkPubliceret2_B,
'IkkePubliceret'
):: KlassePubliceretTilsType
;



klasseEgenskabB_Soegeord1 := ROW(
'soegeordidentifikator_klasseEgenskabB_Soegeord1',
'beskrivelse_klasseEgenskabB_Soegeord1',
'soegeordskategori_klasseEgenskabB_Soegeord1'
)::KlasseSoegeordType
;
klasseEgenskabB_Soegeord2 := ROW(
'soegeordidentifikator_klasseEgenskabB_Soegeord2',
'beskrivelse_klasseEgenskabB_Soegeord2',
'soegeordskategori_klasseEgenskabB_Soegeord2'
)::KlasseSoegeordType
;

klasseEgenskabB_Soegeord3 := ROW(
'soegeordidentifikator_klasseEgenskabB_Soegeord3',
'beskrivelse_klasseEgenskabB_Soegeord3',
'faellessogeord1'
)::KlasseSoegeordType
;
klasseEgenskabB_Soegeord4 := ROW(
'soegeordidentifikator_klasseEgenskabB_Soegeord4',
'beskrivelse_klasseEgenskabB_Soegeord4',
'faellessogeord2'
)::KlasseSoegeordType
;

klasseEgenskab_B := ROW (
'brugervendt_noegle_B',
   'klassebeskrivelse_B',
   'eksempel_faelles',
	'omfang_AB',
   'titel_B',
   'retskilde_B',
   NULL, --aendringsnotat
   'integrationsdata_B',
    ARRAY[klasseEgenskabB_Soegeord1,klasseEgenskabB_Soegeord2,klasseEgenskabB_Soegeord3,klasseEgenskabB_Soegeord4]::KlasseSoegeordType[], --soegeord
   virkEgenskaber_B
) :: KlasseEgenskaberAttrType
;

registrering_B := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidregistrering_AB,
	'Test Note 5') :: registreringBase
	,
ARRAY[klassePubliceret_B,klassePubliceret_B2]::KlassePubliceretTilsType[],
ARRAY[klasseEgenskab_B]::KlasseEgenskaberAttrType[],
ARRAY[klasseRelAnsvarlig_B,klasseRelRedaktoer1_B,klasseRelRedaktoer2_B,klasseRelSideordnede3_B]
) :: KlasseRegistreringType
;

new_uuid_B := as_create_or_import_klasse(registrering_B);


--***********************************


search_result1 :=as_search_klasse(
	null,--TOOD ??
	new_uuid_A,
	ROW (
		ROW(
			TSTZRANGE(current_timestamp,clock_timestamp(),'[]')
			--TSTZRANGE('2014-01-01','2015-01-01','[]')
			,null--Livscykluskode
			,null --uuid
			,null --test note
			)::registreringBase
		,null --KlassePubliceretTilsType
		,null --KlasseEgenskaberAttrType
		,null --relationer
		)::KlasseRegistreringType
	,null--virkningSoeg
	);

RETURN NEXT is(
search_result1,
ARRAY[new_uuid_A]::uuid[],
'simple search on single uuid'
);


search_result1A :=as_search_klasse(
	null,--TOOD ??
	new_uuid_A,
	ROW (
		ROW(
			TSTZRANGE('2014-01-01','2015-01-01','[]')
			,null--Livscykluskode
			,null --uuid
			,null --test note
			)::registreringBase
		,null --KlassePubliceretTilsType
		,null --KlasseEgenskaberAttrType
		,null --relationer
		)::KlasseRegistreringType
	,null--virkningSoeg
	);

RETURN NEXT is(
search_result1A,
ARRAY[]::uuid[],
'simple search on single uuid, with irrelevant system reg time.'
);

--***********************************

search_result2 :=as_search_klasse(
	null,--TOOD ??
	null,
	null,--registrering_A Klasseregistrering_AType
	null--virkningSoeg
	);

expected_result2:=ARRAY[new_uuid_A,new_uuid_B]::uuid[];


RETURN NEXT ok(expected_result2 @> search_result2 and search_result2 @>expected_result2 and array_length(expected_result2,1)=array_length(search_result2,1), 'search null params');



--***********************************
search_result2A :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE('2014-01-01','2014-01-01','[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,null--virkningSoeg
	);

expected_result2A:=ARRAY[]::uuid[];


RETURN NEXT ok(coalesce(array_length(expected_result2A,1),0)=coalesce(array_length(search_result2A,1),0), 'search null params, except for system reg. time');


--***********************************

--search on klasses that has had the state not published at any point in time

search_registrering_3 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	null,null,null,null
				  	)::virkning 
				  ,'IkkePubliceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
null,--ARRAY[klasseEgenskab_B]::KlasseEgenskaberAttrType[],
null--ARRAY[klasseRelAnsvarlig_B,klasseRelRedaktoer1_B,klasseRelRedaktoer2_B]
):: KlasseRegistreringType;

--raise notice 'search_registrering_3,%',search_registrering_3;

search_result3 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_3 --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);

--raise notice 'search for IkkePubliceret returned:%',search_result3;

RETURN NEXT is(
search_result3,
ARRAY[new_uuid_B]::uuid[],
'search state KlassePubliceretTils IkkePubliceret'
);

--***********************************
--search on klasses that has had the state not published at any point in time (but with "invalid" system.reg time )

search_registrering_3A := ROW (
	ROW (
	TSTZRANGE('2014-01-01','2014-12-31','[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	null,null,null,null
				  	)::virkning 
				  ,'IkkePubliceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
null,--ARRAY[klasseEgenskab_B]::KlasseEgenskaberAttrType[],
null--ARRAY[klasseRelAnsvarlig_B,klasseRelRedaktoer1_B,klasseRelRedaktoer2_B]
):: KlasseRegistreringType;

--raise notice 'search_registrering_3A,%',search_registrering_3A;

search_result3A :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_3A --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);

--raise notice 'search for IkkePubliceret returned:%',search_result3A;

RETURN NEXT is(
search_result3A,
ARRAY[]::uuid[],
'search state KlassePubliceretTils IkkePubliceret, system.reg time'
);

--***********************************
--search on klasses that were published on 18-05-2015
search_registrering_4 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-05-18, 2015-05-19]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'Publiceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
null,--ARRAY[klasseEgenskab_B]::KlasseEgenskaberAttrType[],
null--ARRAY[klasseRelAnsvarlig_B,klasseRelRedaktoer1_B,klasseRelRedaktoer2_B]
):: KlasseRegistreringType;



search_result4 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_4 --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);

expected_result4=ARRAY[new_uuid_A,new_uuid_B]::uuid[];


RETURN NEXT ok(expected_result4 @> search_result4 and search_result4 @>expected_result4 and array_length(expected_result4,1)=array_length(search_result4,1), 'search state KlassePubliceretTils Publiceret on 18-05-2015 - 19-05-2015');


--***********************************
--search on klasses that had state 'ikkepubliceret' on 30-06-2015 30-07-2015
search_registrering_5 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-06-30, 2015-07-30]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'IkkePubliceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
null,--ARRAY[klasseEgenskab_B]::KlasseEgenskaberAttrType[],
null--ARRAY[klasseRelAnsvarlig_B,klasseRelRedaktoer1_B,klasseRelRedaktoer2_B]
):: KlasseRegistreringType;



search_result5 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_5 --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);

RETURN NEXT is(
search_result5,
ARRAY[]::uuid[],
'search state KlassePubliceretTils ikkepubliceret on 30-06-2015 30-07-2015'
);

--***********************************
--search on klasses with specific aktoerref and state publiceret
search_registrering_6 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-05-18, 2015-05-19]' :: TSTZRANGE,
				  	(virkPubliceret_B).AktoerRef,
				  	null,null
				  	)::virkning 
				  ,'Publiceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
null,--ARRAY[klasseEgenskab_B]::KlasseEgenskaberAttrType[],
null--ARRAY[klasseRelAnsvarlig_B,klasseRelRedaktoer1_B,klasseRelRedaktoer2_B]
):: KlasseRegistreringType;

search_result6 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_6 --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);

RETURN NEXT is(
search_result6,
ARRAY[new_uuid_B]::uuid[],
'search on klasses with specific aktoerref and state publiceret'
);


--*******************


virkEgenskaber_C :=	ROW (
	'[2014-09-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkAnsvarlig_C :=	ROW (
	'[2014-08-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkRedaktoer1_C :=	ROW (
	'[2014-07-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkRedaktoer2_C :=	ROW (
	'[2013-04-10, 2015-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;

virkPubliceret_C := ROW (
	'[2015-02-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx10'
) :: Virkning
;

virkPubliceret2_C := ROW (
	'[2013-05-18, 2015-02-18)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx143'
) :: Virkning
;


klasseRelAnsvarlig_C := ROW (
	'ansvarlig'::KlasseRelationKode,
		virkAnsvarlig_C,
	uuidAnsvarlig_C,
	null,
	null
) :: KlasseRelationType
;


klasseRelRedaktoer1_C := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer1_C,
	uuidRedaktoer1_C,
	null,
	null
) :: KlasseRelationType
;



klassePubliceret_C := ROW (
virkPubliceret_C,
'Publiceret'
):: KlassePubliceretTilsType
;

klassePubliceret_C2 := ROW (
virkPubliceret2_C,
'IkkePubliceret'
):: KlassePubliceretTilsType
;



klasseEgenskab_C := ROW (
'brugervendt_noegle_C',
   'klassebeskrivelse_C',
   'eksempel_faelles',
	'omfang_C',
   'titel_C',
   'retskilde_C',
   'aendringsnotat_C', --aendringsnotat
   'integrationsdata_C',
    NULL, --soegeord
   virkEgenskaber_C
) :: KlasseEgenskaberAttrType
;


registrering_C := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidregistrering_C,
	'Test Note 1000') :: registreringBase
	,
ARRAY[klassePubliceret_C,klassePubliceret_C2]::KlassePubliceretTilsType[],
ARRAY[klasseEgenskab_C]::KlasseEgenskaberAttrType[],
ARRAY[klasseRelAnsvarlig_C,klasseRelRedaktoer1_C]
) :: KlasseRegistreringType
;

new_uuid_C := as_create_or_import_klasse(registrering_C);

--*******************
--Do a test, that filters on publiceretStatus, egenskaber and relationer



search_registrering_7 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-05-18, 2015-05-19]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'Publiceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
ARRAY[
	ROW(
		NULL, --brugervendtnoegle
   		NULL, --beskrivelse
        NULL, --eksempel
   		NULL, --omfang
   		NULL, --titel
   		'retskilde_C',
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		NULL, --soegeord
   			ROW(
				  	'[2015-01-01, 2015-02-01]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
		)::KlasseEgenskaberAttrType
]::KlasseEgenskaberAttrType[],
ARRAY[
	ROW (
	'redaktoerer'::KlasseRelationKode,
		ROW(
				'[2013-05-01, 2015-04-11]' :: TSTZRANGE,
				 null,null,null
			)::virkning ,
			null,
			null,
			null
	) :: KlasseRelationType
]
):: KlasseRegistreringType;



search_result7 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_7 --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);

RETURN NEXT is(
search_result7,
ARRAY[new_uuid_C]::uuid[],
'search state publiceretStatus, egenskaber and relationer combined'
);


--*******************
--Do a test, that filters on publiceretStatus, egenskaber and relationer


search_registrering_8 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-05-18, 2015-05-19]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'Publiceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
ARRAY[]::KlasseEgenskaberAttrType[],
ARRAY[
	ROW (
	'redaktoerer'::KlasseRelationKode,
		ROW(
				'[2013-05-01, 2015-04-11]' :: TSTZRANGE,
				 null,null,null
			)::virkning ,
			null,
			null,
			null
	) :: KlasseRelationType
]
):: KlasseRegistreringType;


search_result8 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_8 --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);

expected_result8:=ARRAY[new_uuid_B,new_uuid_C]::uuid[];

RETURN NEXT ok(expected_result8 @> search_result8 and search_result8 @>expected_result8 and array_length(expected_result8,1)=array_length(search_result8,1), 'search state publiceretStatus and relationer combined');

--*******************
--Do a test, that filters on soegeord



search_registrering_9 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-05-19, 2015-05-19]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'Publiceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
ARRAY[

ROW(
		NULL, --brugervendtnoegle
   		NULL, --beskrivelse
        'eksempel_faelles', --eksempel
   		NULL, --omfang
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		ARRAY[ROW(null,null,'faellessogeord2')::KlasseSoegeordType], --soegeord
   			ROW(
				  	'[2015-05-13, 2015-05-14]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
		)::KlasseEgenskaberAttrType


]::KlasseEgenskaberAttrType[],
null
):: KlasseRegistreringType;


search_result9 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_9 --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);

expected_result9:=ARRAY[new_uuid_A,new_uuid_B]::uuid[];

RETURN NEXT ok(expected_result9 @> search_result9 and search_result9 @>expected_result9 and array_length(expected_result9,1)=array_length(search_result9,1), 'search state publiceretStatus and soegeord combined');

---*******************
--Do a test, that filters on soegeord (2)



search_registrering_10 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-05-19, 2015-05-19]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'Publiceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
ARRAY[

ROW(
		NULL, --brugervendtnoegle
   		NULL, --beskrivelse
        NULL, --eksempel
   		NULL, --omfang
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		ARRAY[ROW(null,null,'faellessogeord1')::KlasseSoegeordType], --soegeord
   			ROW(
				  	'[2015-04-13, 2015-04-14]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
		)::KlasseEgenskaberAttrType


]::KlasseEgenskaberAttrType[],
null
):: KlasseRegistreringType;


search_result10 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_10 --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);

expected_result10:=ARRAY[new_uuid_B]::uuid[];

RETURN NEXT ok(expected_result10 @> search_result10 and search_result10 @>expected_result10 and array_length(expected_result10,1)=array_length(search_result10,1), 'search state publiceretStatus and soegeord combined 2');


--Do a test, that filters on soegeord (3)



search_registrering_11 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-05-19, 2015-05-19]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'Publiceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
ARRAY[

ROW(
		NULL, --brugervendtnoegle
   		'klassebeskrivelse_C', --beskrivelse
        NULL, --eksempel
   		NULL, --omfang
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		ARRAY[ROW(null,null,'faellessogeord2')::KlasseSoegeordType], --soegeord
   			ROW(
				  	'[2015-05-13, 2015-05-14]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
		)::KlasseEgenskaberAttrType


]::KlasseEgenskaberAttrType[],
null
):: KlasseRegistreringType;


search_result11 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_11 --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);

expected_result11:=ARRAY[]::uuid[];

--raise notice 'search_result11:%, length:%',search_result11,array_length(search_result11,1);

RETURN NEXT ok(coalesce(array_length(search_result11, 1), 0)=0 , 'search state publiceretStatus and soegeord combined 3');

---*******************
--search state publiceretStatus and common egenskab 



search_registrering_12 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-05-19, 2015-05-19]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'Publiceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
ARRAY[

ROW(
		NULL, --brugervendtnoegle
   		NULL, --beskrivelse
        'eksempel_faelles', --eksempel
   		NULL, --omfang
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		NULL, --soegeord
   			ROW(
				  	'[2015-05-13, 2015-05-20]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
		)::KlasseEgenskaberAttrType


]::KlasseEgenskaberAttrType[],
null
):: KlasseRegistreringType;


search_result12 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_12 --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);

expected_result12:=ARRAY[new_uuid_A,new_uuid_B,new_uuid_C]::uuid[];

RETURN NEXT ok(expected_result12 @> search_result12 and search_result12 @>expected_result12 and array_length(expected_result12,1)=array_length(search_result12,1), 'search state publiceretStatus and common egenskab');




---*******************
--Test global virksøg 1


search_registrering_13 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
ARRAY[

ROW(
		NULL, --brugervendtnoegle
   		NULL, --beskrivelse
        'eksempel_faelles', --eksempel
   		NULL, --omfang
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		NULL, --soegeord
   			null
		)::KlasseEgenskaberAttrType


]::KlasseEgenskaberAttrType[],
null
):: KlasseRegistreringType;


search_result13 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_13, --registrering_A Klasseregistrering_AType
	'[2014-10-01, 2014-10-20]' :: TSTZRANGE --virkningSoeg
	);



expected_result13:=ARRAY[new_uuid_C]::uuid[];

RETURN NEXT ok(expected_result13 @> search_result13 and search_result13 @>expected_result13 and array_length(expected_result13,1)=array_length(search_result13,1), 'Test global virksøg 1');


--Test global virksøg 2


search_registrering_14 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
ARRAY[

ROW(
		NULL, --brugervendtnoegle
   		NULL, --beskrivelse
        'eksempel_faelles', --eksempel
   		NULL, --omfang
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		NULL, --soegeord
   			null
		)::KlasseEgenskaberAttrType


]::KlasseEgenskaberAttrType[],
null
):: KlasseRegistreringType;


search_result14 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_14, --registrering_A Klasseregistrering_AType
	'[2014-10-01, 2015-04-12]' :: TSTZRANGE --virkningSoeg
	);

expected_result14:=ARRAY[new_uuid_C,new_uuid_B]::uuid[];

RETURN NEXT ok(expected_result14 @> search_result14 and search_result14 @>expected_result14 and array_length(expected_result14,1)=array_length(search_result14,1), 'Test global virksøg 2');


--**************************************************
--Test global virksøg 3


search_registrering_15 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
ARRAY[

ROW(
		NULL, --brugervendtnoegle
   		NULL, --beskrivelse
        'eksempel_faelles', --eksempel
   		NULL, --omfang
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		NULL, --soegeord
   			ROW(
				  	'[2014-12-20, 2014-12-23]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning
		)::KlasseEgenskaberAttrType


]::KlasseEgenskaberAttrType[],
null
):: KlasseRegistreringType;


search_result15 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_15, --registrering_A Klasseregistrering_AType
	'[2014-10-01, 2015-04-12]' :: TSTZRANGE --virkningSoeg --NOTICE: Should we overruled by more specific virkning supplied above
	);

expected_result15:=ARRAY[new_uuid_C]::uuid[];

--raise notice 'Test global virksøg 3:search_result15:%',to_json(search_result15);

--raise notice 'Test global virksøg 3:expected_result15:%',to_json(expected_result15);

RETURN NEXT ok(expected_result15 @> search_result15 and search_result15 @>expected_result15 and array_length(expected_result15,1)=array_length(search_result15,1), 'Test global virksøg 3');


--**************************************************
--Test global virksøg 4


--***********************************
search_registrering_16 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2015-03-18, 2015-04-19]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'Publiceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
null,--ARRAY[klasseEgenskab_B]::KlasseEgenskaberAttrType[],
null--ARRAY[klasseRelAnsvarlig_B,klasseRelRedaktoer1_B,klasseRelRedaktoer2_B]
):: KlasseRegistreringType;


search_result16 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_16 --registrering_A Klasseregistrering_AType
	,'[2015-01-01, 2015-05-19]' :: TSTZRANGE --virkningSoeg --ATTENTION: Should be overruled by the more specific virkning above
	);

expected_result16=ARRAY[new_uuid_C]::uuid[];

--raise notice 'Test global virksøg 5:search_result16:%',to_json(search_result16);

--raise notice 'Test global virksøg 5:expected_result16:%',to_json(expected_result16);

RETURN NEXT ok(expected_result16 @> search_result16 and search_result16 @>expected_result16 and array_length(expected_result16,1)=array_length(search_result16,1), 'Test global virksøg 4');


--***********************************
--Test global virksøg 5
search_registrering_17 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  NULL--virkning 
				  ,'Publiceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
null,--ARRAY[klasseEgenskab_B]::KlasseEgenskaberAttrType[],
null--ARRAY[klasseRelAnsvarlig_B,klasseRelRedaktoer1_B,klasseRelRedaktoer2_B]
):: KlasseRegistreringType;


search_result17 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_17 --registrering_A Klasseregistrering_AType
	,'[2015-01-01, 2015-02-19]' :: TSTZRANGE --virkningSoeg 
	);

expected_result17=ARRAY[new_uuid_C]::uuid[];

/*
raise notice 'Test global virksøg 5:search_result17:%',to_json(search_result17);

raise notice 'Test global virksøg 5:expected_result17:%',to_json(expected_result17);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result17 @> search_result17 and search_result17 @>expected_result17 and array_length(expected_result17,1)=array_length(search_result17,1), 'Test global virksøg 5');

--***********************************
--'Test global virksøg 6'

search_registrering_18 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
null,--ARRAY[klasseEgenskab_B]::KlasseEgenskaberAttrType[],
null--ARRAY[klasseRelAnsvarlig_B,klasseRelRedaktoer1_B,klasseRelRedaktoer2_B]
):: KlasseRegistreringType;


search_result18 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_18 --registrering_A Klasseregistrering_AType
	,'[2015-01-01, 2015-02-19]' :: TSTZRANGE --virkningSoeg 
	);

expected_result18=ARRAY[new_uuid_A,new_uuid_B,new_uuid_C]::uuid[];

/*
raise notice 'Test global virksøg 5:search_result18:%',to_json(search_result18);

raise notice 'Test global virksøg 5:expected_result18:%',to_json(expected_result18);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result18 @> search_result18 and search_result18 @>expected_result18 and array_length(expected_result18,1)=array_length(search_result18,1), 'Test global virksøg 6');


--***********************************
--'Test global virksøg 7'




search_registrering_19 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
	null,
ARRAY[
	ROW (
	'redaktoerer'::KlasseRelationKode,
		ROW(
				'[2013-05-01, 2015-04-11]' :: TSTZRANGE,
				 null,null,null
			)::virkning ,
			null,
			null,
			null
	) :: KlasseRelationType
]
):: KlasseRegistreringType;


expected_result19:=ARRAY[new_uuid_B,new_uuid_C]::uuid[];


search_result19 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_19 --registrering_A Klasseregistrering_AType
	,'[2013-01-01, 2016-01-01]' :: TSTZRANGE --virkningSoeg  --NOTICE: Should be overridden by more specific virkning above
	);

/*
raise notice 'Test global virksøg 5:search_result19:%',to_json(search_result19);

raise notice 'Test global virksøg 5:expected_result19:%',to_json(expected_result19);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result19 @> search_result19 and search_result19 @>expected_result19 and array_length(expected_result19,1)=array_length(search_result19,1), 'Test global virksøg 7');

--'Test global virksøg 8'


search_registrering_20 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
	null,
ARRAY[
	ROW (
	'redaktoerer'::KlasseRelationKode,
		null,--virkning 
			null,
			null,
			null
	) :: KlasseRelationType
]
):: KlasseRegistreringType;


expected_result20:=ARRAY[new_uuid_C]::uuid[];


search_result20 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_20 --registrering_A Klasseregistrering_AType
	,'[2014-08-01, 2014-08-01]' :: TSTZRANGE --virkningSoeg 
	);

/*
raise notice 'Test global virksøg 5:search_result20:%',to_json(search_result20);

raise notice 'Test global virksøg 5:expected_result20:%',to_json(expected_result20);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result20 @> search_result20 and search_result20 @>expected_result20 and array_length(expected_result20,1)=array_length(search_result20,1), 'Test global virksøg 8');

--******************************

--'Test global virksøg 9'


search_registrering_21 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
	null,
ARRAY[
	ROW (
	'overordnetklasse'::KlasseRelationKode,
		null,--virkning 
			null,
			null,
			null
	) :: KlasseRelationType
]
):: KlasseRegistreringType;


expected_result21:=ARRAY[]::uuid[];


search_result21 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_21 --registrering_A Klasseregistrering_AType
	,'[2014-08-01, 2014-08-01]' :: TSTZRANGE --virkningSoeg 
	);

/*
raise notice 'Test global virksøg 5:search_result21:%',to_json(search_result21);

raise notice 'Test global virksøg 5:expected_result21:%',to_json(expected_result21);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok( coalesce(array_length(expected_result21,1),0)=coalesce(array_length(search_result21,1),0), 'Test global virksøg 9');


--******************************
--Test multiple tilstande requirements 


search_registrering_22 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	'[2013-06-01, 2013-06-30]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'IkkePubliceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
			,ROW(
				  ROW(
				  	'[2015-02-19, 2016-01-30]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
				  ,'Publiceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
			
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
null,--ARRAY[klasseEgenskab_B]::KlasseEgenskaberAttrType[],
null--ARRAY[klasseRelAnsvarlig_B,klasseRelRedaktoer1_B,klasseRelRedaktoer2_B]
):: KlasseRegistreringType;




expected_result22:=ARRAY[new_uuid_C]::uuid[];


search_result22 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_22 --registrering_A Klasseregistrering_AType
	,null
	);

/*
raise notice 'Test global virksøg 5:search_result22:%',to_json(search_result22);

raise notice 'Test global virksøg 5:expected_result22:%',to_json(expected_result22);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result22 @> search_result22 and search_result22 @>expected_result22 and array_length(expected_result22,1)=array_length(search_result22,1), 'Test multiple tilstande requirements');


--******************************
--Test multiple attribute requirements 



search_registrering_23 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
ARRAY[

ROW(
		NULL, --brugervendtnoegle
   		NULL, --beskrivelse
        'eksempel_faelles', --eksempel
   		NULL, --omfang
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		NULL, --soegeord
   			null
		)::KlasseEgenskaberAttrType
,
ROW(
		NULL, --brugervendtnoegle
   		'klassebeskrivelse_A', --beskrivelse
        NULL, --eksempel
   		NULL, --omfang
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		NULL, --soegeord
   			null
		)::KlasseEgenskaberAttrType

]::KlasseEgenskaberAttrType[],
null
):: KlasseRegistreringType;


expected_result23:=ARRAY[new_uuid_A]::uuid[];


search_result23 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_23 --registrering_A Klasseregistrering_AType
	,null
	);

/*
raise notice 'Test global virksøg 5:search_result23:%',to_json(search_result23);

raise notice 'Test global virksøg 5:expected_result23:%',to_json(expected_result23);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result23 @> search_result23 and search_result23 @>expected_result23 and array_length(expected_result23,1)=array_length(search_result23,1), 'Test multiple attribute requirements');

--******************************
--Test multiple relations requirements 


search_registrering_24 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
	null,
ARRAY[
	ROW (
	'redaktoerer'::KlasseRelationKode,
		ROW(
				  	'[2015-05-10, 2015-07-30]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning, 
			null,
			null,
			null
	) :: KlasseRelationType,
	ROW (
	'redaktoerer'::KlasseRelationKode,
		ROW(
				  	'[2015-04-20, 2015-04-20]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning, 
			null,
			null,
			null
	) :: KlasseRelationType
]
):: KlasseRegistreringType;



expected_result24:=ARRAY[new_uuid_C,new_uuid_B]::uuid[];


search_result24 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_24 --registrering_A Klasseregistrering_AType
	,null
	);

/*
raise notice 'Test global virksøg 5:search_result24:%',to_json(search_result24);

raise notice 'Test global virksøg 5:expected_result24:%',to_json(expected_result24);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result24 @> search_result24 and search_result24 @>expected_result24 and array_length(expected_result24,1)=array_length(search_result24,1), 'Test multiple relations requirements');

--******************************
--wildcard search attr 1

search_registrering_25 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
	ARRAY[
	ROW(
		NULL, --brugervendtnoegle
   		NULL, --beskrivelse
        NULL, --eksempel
   		'omfang\_A%', --omfang AB
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		NULL, --soegeord
   			null
		)::KlasseEgenskaberAttrType
	],
	null --ARRAY[] relations
):: KlasseRegistreringType;


/*
firstResult int,--TOOD ??
	{{oio_type}}_uuid uuid,
	registreringObj {{oio_type|title}}RegistreringType,
	virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	maxResults int = 2147483647,
	anyAttrValueArr text[] = '{}'::text[],
	anyuuidArr	uuid[] = '{}'::uuid[]
*/

expected_result25:=ARRAY[new_uuid_A,new_uuid_B]::uuid[];

search_result25 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_25, --registrering_A Klasseregistrering_AType
	null
	);

/*
raise notice 'Test global virksøg 5:search_result25:%',to_json(search_result25);

raise notice 'Test global virksøg 5:expected_result25:%',to_json(expected_result25);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result25 @> search_result25 and search_result25 @>expected_result25 and array_length(expected_result25,1)=array_length(search_result25,1), 'wildcard search attr 1');

--******************************
--vilkaarligAttr search attr 2

search_registrering_26 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
	ARRAY[
	ROW(
		NULL, --brugervendtnoegle
   		NULL, --beskrivelse
        'eksempel_faelles', --eksempel
   		NULL, --omfang AB
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		NULL, --soegeord
   			null
		)::KlasseEgenskaberAttrType
	],
	null --ARRAY[] relations
):: KlasseRegistreringType;


/*
firstResult int,--TOOD ??
	{{oio_type}}_uuid uuid,
	registreringObj {{oio_type|title}}RegistreringType,
	virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	maxResults int = 2147483647,
	anyAttrValueArr text[] = '{}'::text[],
	anyuuidArr	uuid[] = '{}'::uuid[]
*/

expected_result26:=ARRAY[new_uuid_B]::uuid[];

search_result26 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_26, --registrering_A Klasseregistrering_AType
	TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	null,
	ARRAY['brugervendt_noegle_B']::text[]
	);

/*
raise notice 'Test global virksøg 5:search_result26:%',to_json(search_result26);

raise notice 'Test global virksøg 5:expected_result26:%',to_json(expected_result26);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result26 @> search_result26 and search_result26 @>expected_result26 and array_length(expected_result26,1)=array_length(search_result26,1), 'vilkaarligAttr search attr 2');

--******************************
--vilkaarligAttr search attr 3

search_registrering_27 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
	ARRAY[
	ROW(
		NULL, --brugervendtnoegle
   		NULL, --beskrivelse
        NULL, --eksempel
   		'omfang\_AB', --omfang AB
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		NULL, --soegeord
   			null
		)::KlasseEgenskaberAttrType
	],
	null --ARRAY[] relations
):: KlasseRegistreringType;


/*
firstResult int,--TOOD ??
	{{oio_type}}_uuid uuid,
	registreringObj {{oio_type|title}}RegistreringType,
	virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	maxResults int = 2147483647,
	anyAttrValueArr text[] = '{}'::text[],
	anyuuidArr	uuid[] = '{}'::uuid[]
*/

expected_result27:=ARRAY[]::uuid[];

search_result27 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_27, --registrering_A Klasseregistrering_AType
	TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	null,
	ARRAY['brugervendt_noegle_C']::text[]
	);

/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result27);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result27);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(coalesce(array_length(search_result27,1),0)=coalesce(array_length(expected_result27,1),0), 'vilkaarligAttr search attr 3');

--******************************
--vilkaarligAttr search attr 4

expected_result28:=ARRAY[new_uuid_C]::uuid[];

search_result28 :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	null,
	ARRAY['brugervendt_noegle_C']::text[]
	);

/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result28);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result28);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result28 @> search_result28 and search_result28 @>expected_result28 and array_length(expected_result28,1)=array_length(search_result28,1), 'vilkaarligAttr search attr 4');

--******************************
--vilkaarligAttr search attr 5
expected_result29:=ARRAY[new_uuid_A,new_uuid_B]::uuid[];

search_result29 :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	null,
	ARRAY['omfang\_AB']::text[]
	);

/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result29);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result29);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result29 @> search_result29 and search_result29 @>expected_result29 and array_length(expected_result29,1)=array_length(search_result29,1), 'vilkaarligAttr search attr 5');

--******************************
--vilkaarligAttr search attr 6
expected_result29:=ARRAY[new_uuid_A]::uuid[];

search_result29 :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	null,
	ARRAY['omfang\_AB','titel_A']::text[]
	);

/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result29);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result29);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result29 @> search_result29 and search_result29 @>expected_result29 and array_length(expected_result29,1)=array_length(search_result29,1), 'vilkaarligAttr search attr 6');


--******************************
--vilkaarligAttr search attr 7
expected_result30:=ARRAY[new_uuid_B]::uuid[];

search_result30 :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	null,
	ARRAY['omfang\_AB','beskrivelse_klasseEgenskabB_Soegeord4']::text[]
	);

/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result30);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result30);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result30 @> search_result30 and search_result30 @>expected_result30 and array_length(expected_result30,1)=array_length(search_result30,1), 'vilkaarligAttr search attr 7');

--******************************
--vilkaarligAttr search attr 8
expected_result31:=ARRAY[new_uuid_B,new_uuid_A]::uuid[];

search_result31 :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	null,
	ARRAY['omfang\_A%']::text[]
	);

/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result31);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result31);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result31 @> search_result31 and search_result31 @>expected_result31 and array_length(expected_result31,1)=array_length(search_result31,1), 'vilkaarligAttr search attr 8');

--******************************
--vilkaarligAttr search attr 9

expected_result32:=ARRAY[new_uuid_C]::uuid[];

search_result32 :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,'[2014-10-01, 2014-10-20]' :: TSTZRANGE, --virkningSoeg,
	null,
	ARRAY['eksempel_faelles']::text[]
	);
/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result32);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result32);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result32 @> search_result32 and search_result32 @>expected_result32 and array_length(expected_result32,1)=array_length(search_result32,1), 'vilkaarligAttr search attr 9');

--******************************
--vilkaarligRel search attr 1

expected_result33:=ARRAY[new_uuid_B]::uuid[];

search_result33 :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,null, --virkningSoeg,
	null,
	null,
	ARRAY[uuidRedaktoer2_B]::uuid[]
	);
/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result33);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result33);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result33 @> search_result33 and search_result33 @>expected_result33 and array_length(expected_result33,1)=array_length(search_result33,1), 'vilkaarligRel search 1');

--******************************
--vilkaarligRel search attr 2

expected_result34:=ARRAY[new_uuid_A]::uuid[];

search_result34 :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,null, --virkningSoeg,
	null,
	null,
	ARRAY[uuidRedaktoer2_A,uuidAnsvarlig_A]::uuid[]
	);
/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result34);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result34);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result34 @> search_result34 and search_result34 @>expected_result34 and array_length(expected_result34,1)=array_length(search_result34,1), 'vilkaarligRel search 2');

--******************************
--vilkaarligRel search attr 3

expected_result35:=ARRAY[]::uuid[];

search_result35 :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,null, --virkningSoeg,
	null,
	null,
	ARRAY[uuidRedaktoer2_A,uuidAnsvarlig_C]::uuid[]
	);
/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result35);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result35);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(coalesce(array_length(expected_result35,1),0)=coalesce(array_length(search_result35,1),0), 'vilkaarligRel search 3');

--******************************
--vilkaarligRel search attr 4

expected_result36:=ARRAY[new_uuid_B]::uuid[];

search_result36 :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,TSTZRANGE(current_timestamp,current_timestamp,'[]'), --virkningSoeg,
	null,
	ARRAY['eksempel_faelles']::text[],
	ARRAY[uuidAnsvarlig_B]::uuid[]
	);
/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result36);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result36);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result36 @> search_result36 and search_result36 @>expected_result36 and array_length(expected_result36,1)=array_length(search_result36,1), 'vilkaarligRel search 4');


--******************************
--vilkaarligRel search attr 5

expected_result37:=ARRAY[]::uuid[];

search_result37 :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,null, --virkningSoeg,
	null,
	ARRAY['brugervendt_noegle_C'],
	ARRAY[uuidAnsvarlig_A]::uuid[]
	);
/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result37);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result37);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(coalesce(array_length(expected_result37,1),0)=coalesce(array_length(search_result37,1),0), 'vilkaarligRel search 5');

--******************************
--vilkaarligRel search attr 6

expected_result38:=ARRAY[new_uuid_B,new_uuid_A]::uuid[];

search_result38 :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,TSTZRANGE(current_timestamp,current_timestamp,'[]'), --virkningSoeg,
	null,
	null,
	ARRAY[uuidSideordnede_AB]::uuid[]
	);
/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result38);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result38);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result38 @> search_result38 and search_result38 @>expected_result38 and array_length(expected_result38,1)=array_length(search_result38,1), 'vilkaarligRel search 6');

--******************************
--vilkaarligRel search attr 7

expected_result39:=ARRAY[new_uuid_B]::uuid[];

search_result39 :=as_search_klasse(
	null,--TOOD ??
	null,
	ROW(ROW (TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),NULL,NULL,NULL) :: registreringBase,NULL,NULL,NULL):: KlasseRegistreringType
	,TSTZRANGE('2014-02-27','2014-03-30','[]'), --virkningSoeg,
	null,
	null,
	ARRAY[uuidSideordnede_AB]::uuid[]
	);
/*
raise notice 'vilkaarligAttr search attr 3:%',to_json(search_result39);

raise notice 'vilkaarligAttr search attr 3:%',to_json(expected_result39);

raise notice 'Test global virksøg 5:A:%',to_json(registrering_A);
raise notice 'Test global virksøg 5:B:%',to_json(registrering_B);
raise notice 'Test global virksøg 5:C:%',to_json(registrering_C);
*/

RETURN NEXT ok(expected_result39 @> search_result39 and search_result39 @>expected_result39 and array_length(expected_result39,1)=array_length(search_result39,1), 'vilkaarligRel search 7');



-------------------------------------------------------------------------
--we'll update system reg time of reg of klasse C to help facilitate tests
update
	klasse_registrering a
SET 
registrering=ROW (
	TSTZRANGE('2014-01-01','2014-12-31','[]'),
	'Opstaaet'::Livscykluskode,
	uuidregistrering_C,
	'Test Note 1000') :: registreringBase
where
a.klasse_id=new_uuid_C
;
-------------------------------------------------------------------------
--egenskab isoleret

search_registrering_40 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
ARRAY[
ROW(
		NULL, --brugervendtnoegle
   		NULL, --beskrivelse
        'eksempel_faelles', --eksempel
   		NULL, --omfang
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		NULL, --soegeord
   		NULL
		)::KlasseEgenskaberAttrType
]::KlasseEgenskaberAttrType[],
null
):: KlasseRegistreringType;


search_result40 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_40 --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);

expected_result40:=ARRAY[new_uuid_A,new_uuid_B]::uuid[];

--raise notice 'expected_result40:%',to_json(expected_result40);

--raise notice 'search_result40:%',to_json(search_result40);

RETURN NEXT ok(expected_result40 @> search_result40 and search_result40 @>expected_result40 and array_length(expected_result40,1)=array_length(search_result40,1), 'search egenskab isolated, system reg filter');

-------------------------------------------------------------------------
--egenskab isolated - system reg time


search_registrering_41 := ROW (
	ROW (
	TSTZRANGE('2014-01-01','2014-12-31','[]'),
	NULL,
	NULL,
	NULL) :: registreringBase,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
ARRAY[
ROW(
		NULL, --brugervendtnoegle
   		NULL, --beskrivelse
        'eksempel_faelles', --eksempel
   		NULL, --omfang
   		NULL, --titel
   		NULL,
   		NULL, --aendringsnotat
   		NULL, --integrationsdata
   		NULL, --soegeord
   		NULL
		)::KlasseEgenskaberAttrType
]::KlasseEgenskaberAttrType[],
null
):: KlasseRegistreringType;


search_result41 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_41 --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);

expected_result41:=ARRAY[new_uuid_C]::uuid[];

RETURN NEXT ok(expected_result41 @> search_result41 and search_result41 @>expected_result41 and array_length(expected_result41,1)=array_length(search_result41,1), 'search egenskab isolated, system reg time.');

-------------------------------------------------------------------------
--search on klasses that has had the state  published at any point in time (system reg. filtration)

search_registrering_42 := ROW (
	ROW (
	TSTZRANGE('2014-01-01','2014-12-31','[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	ARRAY[
			ROW(
				  ROW(
				  	null,null,null,null
				  	)::virkning 
				  ,'Publiceret'::KlassePubliceretTils
				):: KlassePubliceretTilsType
	],--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
null,--ARRAY[klasseEgenskab_B]::KlasseEgenskaberAttrType[],
null--ARRAY[klasseRelAnsvarlig_B,klasseRelRedaktoer1_B,klasseRelRedaktoer2_B]
):: KlasseRegistreringType;

search_result42 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_42 --registrering_A Klasseregistrering_AType
	,null--virkningSoeg
	);


RETURN NEXT is(
search_result42,
ARRAY[new_uuid_C]::uuid[],
'search state KlassePubliceretTils Publiceret, system reg filter'
);

-------------------------------------------------------------------------
search_registrering_43 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
	null,
ARRAY[
	ROW (
	'redaktoerer'::KlasseRelationKode,
		ROW(
				  	'[2015-05-10, 2015-07-30]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning, 
			null,
			null,
			null
	) :: KlasseRelationType,
	ROW (
	'redaktoerer'::KlasseRelationKode,
		ROW(
				  	'[2015-04-20, 2015-04-20]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning, 
			null,
			null,
			null
	) :: KlasseRelationType
]
):: KlasseRegistreringType;


expected_result43:=ARRAY[new_uuid_B]::uuid[];

search_result43 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_43 --registrering_A Klasseregistrering_AType
	,null
	);


RETURN NEXT ok(expected_result43 @> search_result43 and search_result43 @>expected_result43 and array_length(expected_result43,1)=array_length(search_result43,1), 'search relationer isolated, system reg time.');

-------------------------------------------------------------------------
search_registrering_44 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
	null,
ARRAY[
	ROW (
	'redaktoerer'::KlasseRelationKode,
		ROW(
				  	'[2015-05-10, 2015-07-30]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning, 
			null,
			null,
			null
	) :: KlasseRelationType,
	ROW (
	'redaktoerer'::KlasseRelationKode,
		ROW(
				  	'[2015-04-20, 2015-04-20]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning, 
			null,
			null,
			null
	) :: KlasseRelationType
]
):: KlasseRegistreringType;


expected_result44:=ARRAY[new_uuid_B]::uuid[];

search_result44 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_44 --registrering_A Klasseregistrering_AType
	,null
	);


RETURN NEXT ok(expected_result44 @> search_result44 and search_result44 @>expected_result44 and array_length(expected_result44,1)=array_length(search_result44,1), 'search relationer isolated, system reg time.');

-------------------------------------------------------------------------

search_registrering_45 := ROW (
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	uuidregistrering_AB,
	NULL) :: registreringBase
	,
	null,--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
	null,
	NULL
	):: KlasseRegistreringType;


expected_result45:=ARRAY[new_uuid_B,new_uuid_A]::uuid[];

search_result45 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_45 --registrering_A Klasseregistrering_AType
	,null
	);


RETURN NEXT ok(expected_result45 @> search_result45 and search_result45 @>expected_result45 and array_length(expected_result45,1)=array_length(search_result45,1), 'search aktorref isolated.');

-------------------------------------------------------------------------

--we'll update system reg time of reg of klasse C BACK to normal to help facilitate tests
/*
update
	klasse_registrering a
SET 
registrering=ROW (
	TSTZRANGE('2014-01-01','infinity','[)'),
	'Opstaaet'::Livscykluskode,
	uuidregistrering_C,
	'Test Note 1000') :: registreringBase
where
a.klasse_id=new_uuid_C
;

--GET DIAGNOSTICS rows_affected = ROW_COUNT;
--raise notice 'rows_affected:%',rows_affected;
*/



update_reg_id:=as_update_klasse(
  new_uuid_B, '8762a443-2f60-49c1-bd8e-ecfdef91d48a'::uuid,'Test update'::text,
  'Slettet'::Livscykluskode,          
 registrering_B.attrEgenskaber,
  registrering_B.tilsPubliceret,
  registrering_B.relationer
  ,null
	);

/*
read_Klasse2 := as_read_Klasse(new_uuid_B,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);
*/
--raise notice 'read_Klasse2 - post update:%',to_json(read_Klasse2);

search_registrering_200 := ROW (
	/*
	ROW (
	TSTZRANGE(current_timestamp,clock_timestamp(),'[]'),
	NULL,
	NULL,
	NULL) :: registreringBase
*/
	null
	,null--ARRAY[klassePubliceret_B]::KlassePubliceretTilsType[],
	,ARRAY[
 ROW (
	null--'brugervendt_noegle_C',
   ,null--'klassebeskrivelse_C',
   ,'eksempel_faelles'
	,null--'omfang_C',
   ,null--'titel_C',
   ,null --'retskilde_C'
   ,null--'aendringsnotat_C', --aendringsnotat
   ,null--'integrationsdata_C',
    ,NULL --soegeord
   ,NULL
) :: KlasseEgenskaberAttrType
	]
	,
	NULL
	):: KlasseRegistreringType;


expected_result200:=ARRAY[new_uuid_A]::uuid[];

search_result200 :=as_search_klasse(
	null,--TOOD ??
	null,
	search_registrering_200 --registrering_A Klasseregistrering_AType
	,null
	);

--raise notice 'expected_result200:%',to_json(expected_result200);

--raise notice 'search_result200:%',to_json(search_result200);

RETURN NEXT ok(expected_result200 @> search_result200 and search_result200 @>expected_result200 and array_length(expected_result200,1)=array_length(search_result200,1), 'test if search does not included Livscykluskode [slettet] pr default.');



read_Klasse1 := as_read_Klasse(new_uuid_A,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

read_Klasse2 := as_read_Klasse(new_uuid_B,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);


read_Klasse3 := as_read_Klasse(new_uuid_C,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

--raise notice 'read_Klasse1:%',to_json(read_Klasse1);
--raise notice 'read_Klasse2:%',to_json(read_Klasse2);
--raise notice 'read_Klasse3:%',to_json(read_Klasse3);




END;
$$;
