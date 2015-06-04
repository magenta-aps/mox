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

	expected_result8 uuid[];
	expected_result9 uuid[];
	expected_result10 uuid[];
	expected_result11 uuid[];
	expected_result12 uuid[];

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

RETURN NEXT is(
search_result2,
ARRAY[new_uuid_A,new_uuid_B]::uuid[],
'search null params'
);


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

RETURN NEXT is(
search_result4,
ARRAY[new_uuid_A,new_uuid_B]::uuid[],
'search state KlassePubliceretTils Publiceret on 18-05-2015 - 19-05-2015'
);


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

raise notice 'search_result11:%, length:%',search_result11,array_length(search_result11,1);

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


--Do a test, that filters on soegeord (3)














END;
$$;