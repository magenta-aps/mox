-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


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
	uuidAnsvarlig_A uuid :=uuid_generate_v4();
	uuidRedaktoer1_A uuid :=uuid_generate_v4();
	uuidRedaktoer2_A uuid :=uuid_generate_v4();
	uuidregistrering_A uuid :=uuid_generate_v4();
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
	uuidAnsvarlig_B uuid :=uuid_generate_v4();
	uuidRedaktoer1_B uuid :=uuid_generate_v4();
	uuidRedaktoer2_B uuid :=uuid_generate_v4();
	uuidregistrering_B uuid :=uuid_generate_v4();
	klasseEgenskabB_Soegeord1 KlasseSoegeordType;
	klasseEgenskabB_Soegeord2 KlasseSoegeordType;
	klasseEgenskabB_Soegeord3 KlasseSoegeordType;
	klasseEgenskabB_Soegeord4 KlasseSoegeordType;

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
	search_result2 uuid[];
	search_result3 uuid[];
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

	expected_result2 uuid[];
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

	search_registrering_3 KlasseRegistreringType;
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



klasseRelAnsvarlig_A := ROW (
	'ansvarlig'::KlasseRelationKode,
		virkAnsvarlig_A,
	uuidAnsvarlig_A
) :: KlasseRelationType
;


klasseRelRedaktoer1_A := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer1_A,
	uuidRedaktoer1_A
) :: KlasseRelationType
;



klasseRelRedaktoer2_A := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer2_A,
	uuidRedaktoer2_A
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
	'omfang_A',
   'titel_A',
   'retskilde_A',
   NULL,--'aendringsnotat_text1',
   ARRAY[klasseEgenskabA_Soegeord1,klasseEgenskabA_Soegeord2]::KlasseSoegeordType[], 
   virkEgenskaber_A
) :: KlasseEgenskaberAttrType
;

registrering_A := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidregistrering_A,
	'Test Note 4') :: registreringBase
	,
ARRAY[klassePubliceret_A]::KlassePubliceretTilsType[],
ARRAY[klasseEgenskab_A]::KlasseEgenskaberAttrType[],
ARRAY[klasseRelAnsvarlig_A,klasseRelRedaktoer1_A,klasseRelRedaktoer2_A]
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
	uuidAnsvarlig_B
) :: KlasseRelationType
;


klasseRelRedaktoer1_B := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer1_B,
	uuidRedaktoer1_B
) :: KlasseRelationType
;



klasseRelRedaktoer2_B := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer2_B,
	uuidRedaktoer2_B
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
	'omfang_B',
   'titel_B',
   'retskilde_B',
   NULL, --aendringsnotat
    ARRAY[klasseEgenskabB_Soegeord1,klasseEgenskabB_Soegeord2,klasseEgenskabB_Soegeord3,klasseEgenskabB_Soegeord4]::KlasseSoegeordType[], --soegeord
   virkEgenskaber_B
) :: KlasseEgenskaberAttrType
;

registrering_B := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidregistrering_B,
	'Test Note 5') :: registreringBase
	,
ARRAY[klassePubliceret_B,klassePubliceret_B2]::KlassePubliceretTilsType[],
ARRAY[klasseEgenskab_B]::KlasseEgenskaberAttrType[],
ARRAY[klasseRelAnsvarlig_B,klasseRelRedaktoer1_B,klasseRelRedaktoer2_B]
) :: KlasseRegistreringType
;

new_uuid_B := as_create_or_import_klasse(registrering_B);


--***********************************


search_result1 :=as_search_klasse(
	null,--TOOD ??
	new_uuid_A,
	null,--registrering_A Klasseregistrering_AType
	null--virkningSoeg
	);

RETURN NEXT is(
search_result1,
ARRAY[new_uuid_A]::uuid[],
'simple search on single uuid'
);


search_result2 :=as_search_klasse(
	null,--TOOD ??
	null,
	null,--registrering_A Klasseregistrering_AType
	null--virkningSoeg
	);

expected_result2:=ARRAY[new_uuid_A,new_uuid_B]::uuid[];


RETURN NEXT ok(expected_result2 @> search_result2 and search_result2 @>expected_result2 and array_length(expected_result2,1)=array_length(search_result2,1), 'search null params');



--***********************************
--search on klasses that has had the state not published at any point in time

search_registrering_3 := ROW (
	ROW (
	NULL,
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
--search on klasses that were published on 18-05-2015
search_registrering_4 := ROW (
	ROW (
	NULL,
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
	NULL,
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
	NULL,
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
	uuidAnsvarlig_C
) :: KlasseRelationType
;


klasseRelRedaktoer1_C := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer1_C,
	uuidRedaktoer1_C
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
	NULL,
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
	NULL,
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
	NULL,
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
	NULL,
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
	NULL,
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
	NULL,
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
	NULL,
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
	NULL,
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
	NULL,
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
	NULL,
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
	NULL,
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
	NULL,
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
	NULL,
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
	NULL,
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
	NULL,
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
--Test multiple tilstande ŕequirements 


search_registrering_22 := ROW (
	ROW (
	NULL,
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

RETURN NEXT ok(expected_result22 @> search_result22 and search_result22 @>expected_result22 and array_length(expected_result22,1)=array_length(search_result22,1), 'Test multiple tilstande ŕequirements');


--******************************
--Test multiple attribute ŕequirements 



search_registrering_23 := ROW (
	ROW (
	NULL,
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
--Test multiple relations ŕequirements 


search_registrering_24 := ROW (
	ROW (
	NULL,
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
			null
	) :: KlasseRelationType,
	ROW (
	'redaktoerer'::KlasseRelationKode,
		ROW(
				  	'[2015-04-20, 2015-04-20]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning, 
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

RETURN NEXT ok(expected_result24 @> search_result24 and search_result24 @>expected_result24 and array_length(expected_result24,1)=array_length(search_result24,1), 'Test multiple relations ŕequirements');





END;
$$;