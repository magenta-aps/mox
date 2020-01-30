-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_search_facet()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid_A uuid;
	registrering_A FacetRegistreringType;
	actual_registrering_A registreringBase;
	virkEgenskaber_A Virkning;
	virkAnsvarlig_A Virkning;
	virkRedaktoer1_A Virkning;
	virkRedaktoer2_A Virkning;
	virkPubliceret_A Virkning;
	facetEgenskab_A FacetEgenskaberAttrType;
	facetPubliceret_A FacetPubliceretTilsType;
	facetRelAnsvarlig_A FacetRelationType;
	facetRelRedaktoer1_A FacetRelationType;
	facetRelRedaktoer2_A FacetRelationType;
	uuidAnsvarlig_A uuid :=uuid_generate_v4();
	uuidRedaktoer1_A uuid :=uuid_generate_v4();
	uuidRedaktoer2_A uuid :=uuid_generate_v4();
	uuidregistrering_A uuid :=uuid_generate_v4();
	

	new_uuid_B uuid;
	registrering_B FacetRegistreringType;
	actual_registrering_B registreringBase;
	virkEgenskaber_B Virkning;
	virkAnsvarlig_B Virkning;
	virkRedaktoer1_B Virkning;
	virkRedaktoer2_B Virkning;
	virkPubliceret_B Virkning;
	virkpubliceret2_b Virkning;
	facetEgenskab_B FacetEgenskaberAttrType;
	facetPubliceret_B FacetPubliceretTilsType;
	facetPubliceret_B2 FacetPubliceretTilsType;
	facetRelAnsvarlig_B FacetRelationType;
	facetRelRedaktoer1_B FacetRelationType;
	facetRelRedaktoer2_B FacetRelationType;
	uuidAnsvarlig_B uuid :=uuid_generate_v4();
	uuidRedaktoer1_B uuid :=uuid_generate_v4();
	uuidRedaktoer2_B uuid :=uuid_generate_v4();
	uuidregistrering_B uuid :=uuid_generate_v4();


	new_uuid_C uuid;
	registrering_C FacetRegistreringType;
	actual_registrering_C registreringBase;
	virkEgenskaber_C Virkning;
	virkAnsvarlig_C Virkning;
	virkRedaktoer1_C Virkning;
	virkRedaktoer2_C Virkning;
	virkPubliceret_C Virkning;
	virkpubliceret2_C Virkning;
	facetEgenskab_C FacetEgenskaberAttrType;
	facetPubliceret_C FacetPubliceretTilsType;
	facetPubliceret_C2 FacetPubliceretTilsType;
	facetRelAnsvarlig_C FacetRelationType;
	facetRelRedaktoer1_C FacetRelationType;
	facetRelRedaktoer2_C FacetRelationType;
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
	search_result9B uuid[];

	expected_result2 uuid[];
	expected_result4 uuid[];
	expected_result8 uuid[];
	expected_result9 uuid[];
	expected_result9B uuid[];

	search_registrering_3 FacetRegistreringType;
	search_registrering_4 FacetRegistreringType;
	search_registrering_5 FacetRegistreringType;
	search_registrering_6 FacetRegistreringType;
	search_registrering_7 FacetRegistreringType;
	search_registrering_8 FacetRegistreringType;
	search_registrering_9 FacetRegistreringType;

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



facetRelAnsvarlig_A := ROW (
	'ansvarlig'::FacetRelationKode,
		virkAnsvarlig_A,
	uuidAnsvarlig_A,
	null,
	null
) :: FacetRelationType
;


facetRelRedaktoer1_A := ROW (
	'redaktoerer'::FacetRelationKode,
		virkRedaktoer1_A,
	uuidRedaktoer1_A,
	null,
	null
) :: FacetRelationType
;



facetRelRedaktoer2_A := ROW (
	'redaktoerer'::FacetRelationKode,
		virkRedaktoer2_A,
	uuidRedaktoer2_A,
	null,
	null
) :: FacetRelationType
;


facetPubliceret_A := ROW (
virkPubliceret_A,
'Publiceret'
):: FacetPubliceretTilsType
;


facetEgenskab_A := ROW (
'brugervendt_noegle_text1',
   'facetbeskrivelse_text1',
   'facetplan_text1',
   'facetopbygning_text1',
   'facetophavsret_text1',
   'facetsupplement_text1',
   'retskilde_text1',
   'integrationsdata_text1',
   virkEgenskaber_A
) :: FacetEgenskaberAttrType
;


registrering_A := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidregistrering_A,
	'Test Note 4') :: registreringBase
	,
ARRAY[facetPubliceret_A]::FacetPubliceretTilsType[],
ARRAY[facetEgenskab_A]::FacetEgenskaberAttrType[],
ARRAY[facetRelAnsvarlig_A,facetRelRedaktoer1_A,facetRelRedaktoer2_A]
) :: FacetRegistreringType
;

new_uuid_A := as_create_or_import_facet(registrering_A);



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


facetRelAnsvarlig_B := ROW (
	'ansvarlig'::FacetRelationKode,
		virkAnsvarlig_B,
	uuidAnsvarlig_B,
	null,
	null
) :: FacetRelationType
;


facetRelRedaktoer1_B := ROW (
	'redaktoerer'::FacetRelationKode,
		virkRedaktoer1_B,
	uuidRedaktoer1_B,
	null,
	null
) :: FacetRelationType
;



facetRelRedaktoer2_B := ROW (
	'redaktoerer'::FacetRelationKode,
		virkRedaktoer2_B,
	uuidRedaktoer2_B,
	null,
	null
) :: FacetRelationType
;


facetPubliceret_B := ROW (
virkPubliceret_B,
'Publiceret'
):: FacetPubliceretTilsType
;

facetPubliceret_B2 := ROW (
virkPubliceret2_B,
'IkkePubliceret'
):: FacetPubliceretTilsType
;


facetEgenskab_B := ROW (
'brugervendt_noegle_text2',
   'facetbeskrivelse_text2',
   'facetplan_text2',
   'facetopbygning_text2',
   'facetophavsret_text2',
   'facetsupplement_text2',
   'retskilde_text2',
   'integrationsdata_text2',
   virkEgenskaber_B
) :: FacetEgenskaberAttrType
;


registrering_B := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidregistrering_B,
	'Test Note 5') :: registreringBase
	,
ARRAY[facetPubliceret_B,facetPubliceret_B2]::FacetPubliceretTilsType[],
ARRAY[facetEgenskab_B]::FacetEgenskaberAttrType[],
ARRAY[facetRelAnsvarlig_B,facetRelRedaktoer1_B,facetRelRedaktoer2_B]
) :: FacetRegistreringType
;

new_uuid_B := as_create_or_import_facet(registrering_B);


--***********************************


search_result1 :=as_search_facet(
	null,--TOOD ??
	new_uuid_A,
	null,--registrering_A Facetregistrering_AType
	null--virkningSoeg
	);

RETURN NEXT is(
search_result1,
ARRAY[new_uuid_A]::uuid[],
'simple search on single uuid'
);


search_result2 :=as_search_facet(
	null,--TOOD ??
	null,
	null,--registrering_A Facetregistrering_AType
	null--virkningSoeg
	);

expected_result2:=ARRAY[new_uuid_A,new_uuid_B]::uuid[];

RETURN NEXT ok(expected_result2 @> search_result2 and search_result2 @>expected_result2 and array_length(expected_result2,1)=array_length(search_result2,1), 'search null params');


--***********************************
--search on facets that has had the state not published at any point in time

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
				  ,'IkkePubliceret'::FacetPubliceretTils
				):: FacetPubliceretTilsType
	],--ARRAY[facetPubliceret_B]::FacetPubliceretTilsType[],
null,--ARRAY[facetEgenskab_B]::FacetEgenskaberAttrType[],
null--ARRAY[facetRelAnsvarlig_B,facetRelRedaktoer1_B,facetRelRedaktoer2_B]
):: FacetRegistreringType;

--raise notice 'search_registrering_3,%',search_registrering_3;

search_result3 :=as_search_facet(
	null,--TOOD ??
	null,
	search_registrering_3, --registrering_A Facetregistrering_AType
	null--virkningSoeg
	);

--raise notice 'search for IkkePubliceret returned:%',search_result3;

RETURN NEXT is(
search_result3,
ARRAY[new_uuid_B]::uuid[],
'search state FacetPubliceretTils IkkePubliceret'
);

--***********************************
--search on facets that were published on 18-05-2015
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
				  ,'Publiceret'::FacetPubliceretTils
				):: FacetPubliceretTilsType
	],--ARRAY[facetPubliceret_B]::FacetPubliceretTilsType[],
null,--ARRAY[facetEgenskab_B]::FacetEgenskaberAttrType[],
null--ARRAY[facetRelAnsvarlig_B,facetRelRedaktoer1_B,facetRelRedaktoer2_B]
):: FacetRegistreringType;



search_result4 :=as_search_facet(
	null,--TOOD ??
	null,
	search_registrering_4, --registrering_A Facetregistrering_AType
	null--virkningSoeg
	);



expected_result4:=ARRAY[new_uuid_A,new_uuid_B]::uuid[];

RETURN NEXT ok(expected_result4 @> search_result4 and search_result4 @>expected_result4 and array_length(expected_result4,1)=array_length(search_result4,1), 'search on facets that were published on 18-05-2015');


--***********************************
--search on facets that had state 'ikkepubliceret' on 30-06-2015 30-07-2015
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
				  ,'IkkePubliceret'::FacetPubliceretTils
				):: FacetPubliceretTilsType
	],--ARRAY[facetPubliceret_B]::FacetPubliceretTilsType[],
null,--ARRAY[facetEgenskab_B]::FacetEgenskaberAttrType[],
null--ARRAY[facetRelAnsvarlig_B,facetRelRedaktoer1_B,facetRelRedaktoer2_B]
):: FacetRegistreringType;



search_result5 :=as_search_facet(
	null,--TOOD ??
	null,
	search_registrering_5, --registrering_A Facetregistrering_AType
	null--virkningSoeg
	);

RETURN NEXT is(
search_result5,
ARRAY[]::uuid[],
'search state FacetPubliceretTils ikkepubliceret on 30-06-2015 30-07-2015'
);

--***********************************
--search on facets with specific aktoerref and state publiceret
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
				  ,'Publiceret'::FacetPubliceretTils
				):: FacetPubliceretTilsType
	],--ARRAY[facetPubliceret_B]::FacetPubliceretTilsType[],
null,--ARRAY[facetEgenskab_B]::FacetEgenskaberAttrType[],
null--ARRAY[facetRelAnsvarlig_B,facetRelRedaktoer1_B,facetRelRedaktoer2_B]
):: FacetRegistreringType;

search_result6 :=as_search_facet(
	null,--TOOD ??
	null,
	search_registrering_6, --registrering_A Facetregistrering_AType
	null--virkningSoeg
	);

RETURN NEXT is(
search_result6,
ARRAY[new_uuid_B]::uuid[],
'search on facets with specific aktoerref and state publiceret'
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


facetRelAnsvarlig_C := ROW (
	'ansvarlig'::FacetRelationKode,
		virkAnsvarlig_C,
	uuidAnsvarlig_C,
	null,
	null
) :: FacetRelationType
;


facetRelRedaktoer1_C := ROW (
	'redaktoerer'::FacetRelationKode,
		virkRedaktoer1_C,
	uuidRedaktoer1_C,
	null,
	null
) :: FacetRelationType
;



facetPubliceret_C := ROW (
virkPubliceret_C,
'Publiceret'
):: FacetPubliceretTilsType
;

facetPubliceret_C2 := ROW (
virkPubliceret2_C,
'IkkePubliceret'
):: FacetPubliceretTilsType
;


facetEgenskab_C := ROW (
'brugervendt_noegle_text3',
   'facetbeskrivelse_text3',
   'facetplan_text3',
   'facetopbygning_text3',
   'facetophavsret_text3',
   'facetsupplement_text3',
   'retskilde_text3',
   'integrationsdata_text3',
   virkEgenskaber_C
) :: FacetEgenskaberAttrType
;


registrering_C := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidregistrering_C,
	'Test Note 993') :: registreringBase
	,
ARRAY[facetPubliceret_C,facetPubliceret_C2]::FacetPubliceretTilsType[],
ARRAY[facetEgenskab_C]::FacetEgenskaberAttrType[],
ARRAY[facetRelAnsvarlig_C,facetRelRedaktoer1_C]
) :: FacetRegistreringType
;

new_uuid_C := as_create_or_import_facet(registrering_C);

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
				  ,'Publiceret'::FacetPubliceretTils
				):: FacetPubliceretTilsType
	],--ARRAY[facetPubliceret_B]::FacetPubliceretTilsType[],
ARRAY[
	ROW(
		NULL,
   		NULL,
        NULL,
   		NULL,
   		NULL,
   		'facetsupplement_text3',
   		NULL,
        NULL,
   			ROW(
				  	'[2015-01-01, 2015-02-01]' :: TSTZRANGE,
				  	null,null,null
				  	)::virkning 
		)::FacetEgenskaberAttrType
]::FacetEgenskaberAttrType[],
ARRAY[
	ROW (
	'redaktoerer'::FacetRelationKode,
		ROW(
				'[2013-05-01, 2015-04-11]' :: TSTZRANGE,
				 null,null,null
			)::virkning ,
			null,
			null,
			null
	) :: FacetRelationType
]
):: FacetRegistreringType;



search_result7 :=as_search_facet(
	null,--TOOD ??
	null,
	search_registrering_7, --registrering_A Facetregistrering_AType
	null--virkningSoeg
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
				  ,'Publiceret'::FacetPubliceretTils
				):: FacetPubliceretTilsType
	],--ARRAY[facetPubliceret_B]::FacetPubliceretTilsType[],
ARRAY[]::FacetEgenskaberAttrType[],
ARRAY[
	ROW (
	'redaktoerer'::FacetRelationKode,
		ROW(
				'[2013-05-01, 2015-04-11]' :: TSTZRANGE,
				 null,null,null
			)::virkning ,
			null,
			null,
			null
	) :: FacetRelationType
]
):: FacetRegistreringType;



search_result8 :=as_search_facet(
	null,--TOOD ??
	null,
	search_registrering_8, --registrering_A Facetregistrering_AType
	null--virkningSoeg
	);

expected_result8:=ARRAY[new_uuid_B,new_uuid_C]::uuid[];

RETURN NEXT ok(expected_result8 @> search_result8 and search_result8 @>expected_result8 and array_length(expected_result8,1)=array_length(search_result8,1), 'search state publiceretStatus and relationer combined');

/************************/
--test if search filters is filtered the rigth way, if access criteria is met.

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
				  ,'Publiceret'::FacetPubliceretTils
				):: FacetPubliceretTilsType
	],--ARRAY[facetPubliceret_B]::FacetPubliceretTilsType[],
	null --ARRAY[]::FacetEgenskaberAttrType[],
	,null --relations

):: FacetRegistreringType;



search_result9 :=as_search_facet(
	null,--TOOD ??
	null,
	search_registrering_9, --registrering_A Facetregistrering_AType
	null--virkningSoeg
	,null --maxResults
	,null --anyAttrValueArr
	,null --anyuuidArr
	,null --anyurnArr
	,ARRAY[
	 ROW (
	 	null --reg base
	 	,null --states
	 	,ARRAY[
		 	ROW (
			null --'brugervendt_noegle_text3',
	   		,null--'facetbeskrivelse_text3',
	   		,'facetplan_text1' --,
	  		,null --'facetopbygning_text3',
	   		,null --'facetophavsret_text3',
	   		,null --'facetsupplement_text3',
	   		,null
            ,null
	   		,null
			) :: FacetEgenskaberAttrType		
	 	]::FacetEgenskaberAttrType[] 
	 	,null --relationer
	 	)::FacetRegistreringType
	 ,ROW (
	 		null --reg base
	 	,null --states
	 	,ARRAY[
		 	ROW (
			null --'brugervendt_noegle_text3',
	   		,null--'facetbeskrivelse_text3',
	   		,'facetplan_text2' --,
	  		,null --'facetopbygning_text3',
	   		,null --'facetophavsret_text3',
	   		,null --'facetsupplement_text3',
            ,null
	   		,null
	   		,null
			) :: FacetEgenskaberAttrType
			]
			::FacetEgenskaberAttrType[] 
	 	,null --relationer
	 	)::FacetRegistreringType
	 	

	]::FacetRegistreringType[]
);

expected_result9:=ARRAY[new_uuid_A,new_uuid_B]::uuid[];

RETURN NEXT ok(expected_result9 @> search_result9 and search_result9 @>expected_result9 and array_length(expected_result9,1)=array_length(search_result9,1), 'search filter on stipulated access criteria #1');

--try same search_registrering_9, but his time don't supply any auth criteria

expected_result9B:=ARRAY[new_uuid_A,new_uuid_B,new_uuid_C]::uuid[];


search_result9B :=as_search_facet(
	null,--TOOD ??
	null,
	search_registrering_9, --NOTICE search_registrering_9
	null--virkningSoeg
	);

RETURN NEXT ok(expected_result9B @> search_result9B and search_result9B @>expected_result9B and array_length(expected_result9B,1)=array_length(search_result9B,1), 'no search filter, when no stipulated criteria #2');






END;
$$;
