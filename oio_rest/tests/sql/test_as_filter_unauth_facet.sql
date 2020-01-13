-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_filter_unauth_facet()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuidA uuid;
	new_uuidB uuid;
	new_uuidC uuid;
	registrering FacetRegistreringType;
	registrering2 FacetRegistreringType;
	registrering3 FacetRegistreringType;
	virkEgenskaber Virkning;
	virkEgenskaberB Virkning;
	virkEgenskaberC Virkning;
	virkEgenskaberC2 Virkning;
	virkEgenskaberD Virkning;
	virkAnsvarlig Virkning;
	virkRedaktoer1 Virkning;
	virkRedaktoer2 Virkning;
	virkPubliceret Virkning;
	virkPubliceretB Virkning;
	virkPubliceretC Virkning;
	facetEgenskabA FacetEgenskaberAttrType;
	facetEgenskabB FacetEgenskaberAttrType;
	facetEgenskabC FacetEgenskaberAttrType;
	facetEgenskabC2 FacetEgenskaberAttrType;
	facetPubliceret FacetPubliceretTilsType;
	facetPubliceretB FacetPubliceretTilsType;
	facetPubliceretC FacetPubliceretTilsType;
	facetRelAnsvarlig FacetRelationType;
	facetRelRedaktoer1 FacetRelationType;
	facetRelRedaktoer2 FacetRelationType;
	uuidAnsvarlig uuid :='e8477d45-a525-4b71-b0fa-eb25bb3c4b23'::uuid;
	uuidRedaktoer1 uuid :='55c3dc9c-60f2-4543-8971-7d1db40c4864'::uuid;
	uuidRedaktoer2 uuid :='c721b26d-daca-461a-a4ca-ec072f9ab9a7'::uuid;
	uuidRegistrering uuid :='107244b5-f00c-4679-a97a-b436176f05d5'::uuid;
	actual_facets1 FacetType[];
	expected_facets1 FacetType[];
	override_timeperiod1 TSTZRANGE;
	override_timeperiod2 TSTZRANGE;

	filter_reg4 FacetRegistreringType;
	filter_reg5 FacetRegistreringType;
	filter_reg6 FacetRegistreringType;
	filter_reg7A FacetRegistreringType;
	filter_reg7B FacetRegistreringType;
	filter_reg8A FacetRegistreringType;
	filter_reg8B FacetRegistreringType;
	filter_reg8C FacetRegistreringType;
	filter_reg9A FacetRegistreringType;
	filter_reg9B FacetRegistreringType;
	filter_reg9C FacetRegistreringType;
	filter_reg10A FacetRegistreringType;
	filter_reg10B FacetRegistreringType;
	filter_reg10C FacetRegistreringType;
	actual_result1 uuid[];
	actual_result2 uuid[];
	actual_result3 uuid[];
	actual_result4 uuid[];
	actual_result5 uuid[];
	actual_result6 uuid[];
	actual_result7 uuid[];
	actual_result8 uuid[];
	actual_result9 uuid[];
	actual_result10 uuid[];
	expected_result1 uuid[];
	expected_result2 uuid[];
	expected_result3 uuid[];
	expected_result4 uuid[];
	expected_result5 uuid[];
	expected_result6 uuid[];
	expected_result7 uuid[];
	expected_result8 uuid[];
	expected_result9 uuid[];
	expected_result10 uuid[];
BEGIN



virkEgenskaber :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          'ed4dc687-59e3-4b79-8f14-0f60a0145901'::uuid,
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkEgenskaberB :=	ROW (
	'[2014-05-13, infinity)' :: TSTZRANGE,
          '48fcbc8b-4c72-4466-9dcc-0451f57b5b52'::uuid,
          'Bruger',
          'NoteEx7'
          ) :: Virkning
;


virkEgenskaberC :=	ROW (
	'[2014-05-13, 2015-01-01)' :: TSTZRANGE,
          '48fcbc8b-4c72-4466-9dcc-0451f57b5b52'::uuid,
          'Bruger',
          'NoteEx7'
          ) :: Virkning
;

virkEgenskaberC2 :=	ROW (
	'[2015-01-01, infinity)' :: TSTZRANGE,
          '98fcbc8b-4c72-4466-9dcc-0451f57b5b55'::uuid,
          'Bruger',
          'NoteEx8'
          ) :: Virkning
;


virkAnsvarlig :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          '7ac7ba19-8d41-427d-9353-907f2b09c011'::uuid,
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkRedaktoer1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          '6892a667-63d9-4ecd-ada1-173f4d7d0c3e'::uuid,
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkRedaktoer2 :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          'df93d345-e332-47f3-81f2-25a4bb6ae39e'::uuid,
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;


virkPubliceret:=	ROW (
	'[2015-05-01, infinity)' :: TSTZRANGE,
          'e6a1beb5-0c7e-4299-984a-64aa3963aa4a'::uuid,
          'Bruger',
          'NoteEx8'
          ) :: Virkning
;

virkPubliceretB:=	ROW (
	'[2014-05-13, infinity)' :: TSTZRANGE,
          '42fbf12c-da1c-4f2e-8ee7-995a4b3dd6cf'::uuid,
          'Bruger',
          'NoteEx9'
          ) :: Virkning
;


virkPubliceretC:=	ROW (
	'[2013-05-13, infinity)' :: TSTZRANGE,
          '02fbf12c-da1c-4f2e-8ee7-995a4b3dd6c7'::uuid,
          'Bruger',
          'NoteEx9'
          ) :: Virkning
;



facetRelAnsvarlig := ROW (
	'ansvarlig'::FacetRelationKode,
		virkAnsvarlig,
	uuidAnsvarlig,
	null,
	null
) :: FacetRelationType
;


facetRelRedaktoer1 := ROW (
	'redaktoerer'::FacetRelationKode,
		virkRedaktoer1,
	uuidRedaktoer1,
	null,
	null
) :: FacetRelationType
;



facetRelRedaktoer2 := ROW (
	'redaktoerer'::FacetRelationKode,
		virkRedaktoer2,
	uuidRedaktoer2,
	null,
	null
) :: FacetRelationType
;


facetPubliceret := ROW (
virkPubliceret,
'Publiceret'
):: FacetPubliceretTilsType
;

facetPubliceretB := ROW (
virkPubliceretB,
'IkkePubliceret'
):: FacetPubliceretTilsType
;


facetPubliceretC := ROW (
virkPubliceretC,
'Publiceret'
):: FacetPubliceretTilsType
;



facetEgenskabA := ROW (
'brugervendt_noegle_A',
   'facetbeskrivelse_A',
   'facetplan_ABC',
   'facetopbygning_AB',
   'facetophavsret_A',
   'facetsupplement_A',
   NULL,--'retskilde_text1',
   'facetintegrationsdata_A',
   virkEgenskaber
) :: FacetEgenskaberAttrType
;

facetEgenskabB := ROW (
'brugervendt_noegle_B',
   'facetbeskrivelse_B',
   'facetplan_ABC',
   'facetopbygning_AB',
   'facetophavsret_BC',
   'facetsupplement_B',
   NULL, --restkilde
   'facetintegrationsdata_B',
   virkEgenskaberB
) :: FacetEgenskaberAttrType
;

facetEgenskabC := ROW (
'brugervendt_noegle_C',
   'facetbeskrivelse_C',
   'facetplan_ABC',
   'facetopbygning_C',
   'facetophavsret_BC',
   'facetsupplement_C',
   NULL, --restkilde
   'facetintegrationsdata_C',
   virkEgenskaberC
) :: FacetEgenskaberAttrType
;


facetEgenskabC2 := ROW (
'brugervendt_noegle_C2',
   'facetbeskrivelse_C2',
   'facetplan_C',
   'facetopbygning_C2',
   'facetophavsret_BC',
   'facetsupplement_C2',
   'restkilde_C2',
   'facetintegrationsdata_C',
   virkEgenskaberC2
) :: FacetEgenskaberAttrType
;

registrering := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
ARRAY[facetPubliceret]::FacetPubliceretTilsType[],
ARRAY[facetEgenskabA]::FacetEgenskaberAttrType[],
ARRAY[facetRelRedaktoer1,facetRelRedaktoer2,facetRelAnsvarlig]
) :: FacetRegistreringType
;

registrering2 := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 27') :: RegistreringBase
	,
ARRAY[facetPubliceretB]::FacetPubliceretTilsType[],
ARRAY[facetEgenskabB]::FacetEgenskaberAttrType[],
ARRAY[facetRelRedaktoer1]
) :: FacetRegistreringType
;


registrering3 := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 85') :: RegistreringBase
	,
ARRAY[facetPubliceretC],
ARRAY[facetEgenskabC,facetEgenskabC2]::FacetEgenskaberAttrType[],
null
) :: FacetRegistreringType
;

new_uuidA := as_create_or_import_facet(registrering);
new_uuidB := as_create_or_import_facet(registrering2);
new_uuidC := as_create_or_import_facet(registrering3);


/***************************************/
expected_result1:=ARRAY[new_uuidA,new_uuidB,new_uuidC];
actual_result1:=_as_filter_unauth_facet(array[new_uuidA,new_uuidB,new_uuidC]::uuid[],null);

RETURN NEXT ok( coalesce(array_length(expected_result1,1),0)=coalesce(array_length(actual_result1,1),0) AND actual_result1 @>expected_result1,'Test for null criteria');


expected_result2:=ARRAY[]::uuid[];
actual_result2:=_as_filter_unauth_facet(array[new_uuidA,new_uuidB,new_uuidC]::uuid[],array[]::FacetRegistreringType[]);

RETURN NEXT ok( coalesce(array_length(expected_result2,1),0)=coalesce(array_length(actual_result2,1),0) AND actual_result2 @>expected_result2,'Test for empty criteria array');



expected_result3:=ARRAY[]::uuid[];
actual_result3:=_as_filter_unauth_facet(array[]::uuid[],array[]::FacetRegistreringType[]);

RETURN NEXT ok( coalesce(array_length(expected_result3,1),0)=coalesce(array_length(actual_result3,1),0) AND actual_result3 @>expected_result3,'Test for empty uuid array');

/***************************************/

filter_reg4:=ROW(
	null --reg base
	,ARRAY[]::FacetPubliceretTilsType[]
	,ARRAY[
		ROW(
			null --'brugervendt_noegle_C',
   			,null --'facetbeskrivelse_C',
   			,'facetplan_ABC'
   			,null --'facetopbygning_C',
   			,null --'facetophavsret_C',
   			,null --'facetsupplement_C',
   			,NULL --restkilde
            ,NULL --'facetintegrationsdata_C',
   			,null --virkEgenskaberC
			)::FacetEgenskaberAttrType
	]::FacetEgenskaberAttrType[]
	,ARRAY[]::FacetRelationType[]
)::FacetRegistreringType;


expected_result4:=array[new_uuidA,new_uuidB]::uuid[];
actual_result4:=_as_filter_unauth_facet(array[new_uuidA,new_uuidB,new_uuidC]::uuid[],array[filter_reg4]::FacetRegistreringType[]);

RETURN NEXT ok( coalesce(array_length(expected_result4,1),0)=coalesce(array_length(actual_result4,1),0) AND actual_result4 @>expected_result4,'Test #4');

/***************************************/


filter_reg5:=ROW(
	null --reg base
	,ARRAY[
			ROW(
				null,
				'Publiceret'
				)::FacetPubliceretTilsType
			]::FacetPubliceretTilsType[]
	,ARRAY[
		ROW(
			null --'brugervendt_noegle_C',
   			,null --'facetbeskrivelse_C',
   			,'facetplan_ABC'
   			,null --'facetopbygning_C',
   			,null --'facetophavsret_C',
   			,null --'facetsupplement_C',
   			,NULL --restkilde
            ,NULL --'facetintegrationsdata_C',
   			,null --virkEgenskaberC
			)::FacetEgenskaberAttrType
	]::FacetEgenskaberAttrType[]
	,ARRAY[]::FacetRelationType[]
)::FacetRegistreringType;


expected_result5:=array[new_uuidA]::uuid[];
actual_result5:=_as_filter_unauth_facet(array[new_uuidA,new_uuidB,new_uuidC]::uuid[],array[filter_reg5]::FacetRegistreringType[]);

RETURN NEXT ok( coalesce(array_length(expected_result5,1),0)=coalesce(array_length(actual_result5,1),0) AND actual_result5 @>expected_result5,'Test #5');

/***************************************/

filter_reg6:=ROW(
	null --reg base
	,null --ARRAY[]::FacetPubliceretTilsType[]
	,ARRAY[
		ROW(
			null --'brugervendt_noegle_C',
   			,null --'facetbeskrivelse_C',
   			,'facetplan_ABC'
   			,'facetopbygning_AB' --'facetopbygning_C',
   			,null --'facetophavsret_C',
   			,null --'facetsupplement_C',
   			,NULL --restkilde
            ,NULL --'facetintegrationsdata_C',
   			,null --virkEgenskaberC
			)::FacetEgenskaberAttrType
		,
		ROW(
			'brugervendt_noegle_B'
   			,null --'facetbeskrivelse_C',
   			,null
   			,null --'facetopbygning_C',
   			,null --'facetophavsret_C',
   			,null --'facetsupplement_C',
   			,NULL --restkilde
            ,NULL --'facetintegrationsdata_C',
   			,null --virkEgenskaberC
			)::FacetEgenskaberAttrType
	]::FacetEgenskaberAttrType[]
	,null --ARRAY[]::FacetRelationType[]
)::FacetRegistreringType;


expected_result6:=array[new_uuidB]::uuid[];
actual_result6:=_as_filter_unauth_facet(array[new_uuidA,new_uuidB,new_uuidC]::uuid[],array[filter_reg6]::FacetRegistreringType[]);

RETURN NEXT ok( coalesce(array_length(expected_result6,1),0)=coalesce(array_length(actual_result6,1),0) AND actual_result6 @>expected_result6,'Test #6');

/***************************************/
filter_reg7A:=ROW(
	null --reg base
	,null --ARRAY[]::FacetPubliceretTilsType[]
	,ARRAY[
		ROW(
			null --'brugervendt_noegle_C',
   			,null --'facetbeskrivelse_C',
   			,'facetplan_ABC'
   			,'facetopbygning_AB' --'facetopbygning_C',
   			,null --'facetophavsret_C',
   			,null --'facetsupplement_C',
   			,NULL --restkilde
            ,NULL --'facetintegrationsdata_C',
   			,null --virkEgenskaberC
			)::FacetEgenskaberAttrType
	]::FacetEgenskaberAttrType[]
	,null --ARRAY[]::FacetRelationType[]
)::FacetRegistreringType;

filter_reg7B:=ROW(
	null --reg base
	,null --ARRAY[]::FacetPubliceretTilsType[]
	,ARRAY[
		ROW(
			'brugervendt_noegle_B'
   			,null --'facetbeskrivelse_C',
   			,null
   			,null --'facetopbygning_C',
   			,null --'facetophavsret_C',
   			,null --'facetsupplement_C',
   			,NULL --restkilde
            ,NULL --'facetintegrationsdata_C',
   			,null --virkEgenskaberC
			)::FacetEgenskaberAttrType
	]::FacetEgenskaberAttrType[]
	,null --ARRAY[]::FacetRelationType[]
)::FacetRegistreringType;



expected_result7:=array[new_uuidA,new_uuidB]::uuid[];
actual_result7:=_as_filter_unauth_facet(array[new_uuidA,new_uuidB,new_uuidC]::uuid[],array[filter_reg7A,filter_reg7B]::FacetRegistreringType[]);

RETURN NEXT ok( coalesce(array_length(expected_result7,1),0)=coalesce(array_length(actual_result7,1),0) AND actual_result7 @>expected_result7,'Test #7');


/***************************************/


filter_reg8A:=ROW(
	null --reg base
	,ARRAY[ROW(
				null,
				'IkkePubliceret'
				)::FacetPubliceretTilsType
			]::FacetPubliceretTilsType[]
	,ARRAY[]::FacetEgenskaberAttrType[]
	,null --ARRAY[]::FacetRelationType[]
)::FacetRegistreringType;

filter_reg8B:=ROW(
	null --reg base
	,null --ARRAY[]::FacetPubliceretTilsType[]
	,ARRAY[
		ROW(
			null
   			,null --'facetbeskrivelse_C',
   			,null
   			,null --'facetopbygning_C',
   			,null --'facetophavsret_C',
   			,'facetsupplement_C2' --'facetsupplement_C',
   			,NULL --restkilde
            ,NULL --'facetintegrationsdata_C',
   			,null --virkEgenskaberC
			)::FacetEgenskaberAttrType
	]::FacetEgenskaberAttrType[]
	,null --ARRAY[]::FacetRelationType[]
)::FacetRegistreringType;


filter_reg8C:=ROW(
	null --reg base
	,null --ARRAY[]::FacetPubliceretTilsType[]
	, null--ARRAY[]::FacetEgenskaberAttrType[]
	,ARRAY[
		 ROW (
			'ansvarlig'::FacetRelationKode,
				null,
			uuidAnsvarlig,
			null,
			null
		) :: FacetRelationType
	]::FacetRelationType[]
)::FacetRegistreringType;


expected_result8:=array[new_uuidA,new_uuidB,new_uuidC]::uuid[];
actual_result8:=_as_filter_unauth_facet(array[new_uuidA,new_uuidB,new_uuidC]::uuid[],array[filter_reg8A,filter_reg8B,filter_reg8C]::FacetRegistreringType[]);


--RAISE NOTICE 'expected_result8:%',expected_result8 ;
--RAISE NOTICE 'actual_result8:%',actual_result8 ;

RETURN NEXT ok( coalesce(array_length(expected_result8,1),0)=coalesce(array_length(actual_result8,1),0) AND actual_result8 @>expected_result8,'Test #8');


/***************************************/


filter_reg9A:=ROW(
	null --reg base
	,ARRAY[ROW(
				null,
				'IkkePubliceret'
				)::FacetPubliceretTilsType
			]::FacetPubliceretTilsType[]
	,ARRAY[]::FacetEgenskaberAttrType[]
	,ARRAY[
		 ROW (
			'ansvarlig'::FacetRelationKode,
				null,
			uuidAnsvarlig,
			null,
			null
		) :: FacetRelationType--ARRAY[]::FacetRelationType[]
		 ]
)::FacetRegistreringType;

filter_reg9B:=ROW(
	null --reg base
	,null --ARRAY[]::FacetPubliceretTilsType[]
	,ARRAY[
		ROW(
			null
   			,null --'facetbeskrivelse_C',
   			,null
   			,null --'facetopbygning_C',
   			,null --'facetophavsret_C',
   			,'facetsupplement_C2' --'facetsupplement_C',
   			,NULL --restkilde
            ,NULL --'facetintegrationsdata_C',
   			,null --virkEgenskaberC
			)::FacetEgenskaberAttrType
	]::FacetEgenskaberAttrType[]
	,null --ARRAY[]::FacetRelationType[]
)::FacetRegistreringType;


filter_reg9C:=ROW(
	null --reg base
	,null --ARRAY[]::FacetPubliceretTilsType[]
	, null--ARRAY[]::FacetEgenskaberAttrType[]
	,ARRAY[
		 ROW (
			'ansvarlig'::FacetRelationKode,
				null,
			uuidAnsvarlig,
			null,
			null
		) :: FacetRelationType
	]::FacetRelationType[]
)::FacetRegistreringType;


expected_result9:=array[new_uuidA,new_uuidC]::uuid[];
actual_result9:=_as_filter_unauth_facet(array[new_uuidA,new_uuidB,new_uuidC]::uuid[],array[filter_reg9A,filter_reg9B,filter_reg9C]::FacetRegistreringType[]);


--RAISE NOTICE 'expected_result9:%',expected_result9 ;
--RAISE NOTICE 'actual_result9:%',actual_result9 ;

RETURN NEXT ok( coalesce(array_length(expected_result9,1),0)=coalesce(array_length(actual_result9,1),0) AND actual_result9 @>expected_result9,'Test #9');

/***************************************/

filter_reg10A:=ROW(
	null --reg base
	,ARRAY[ROW(
				null,
				'IkkePubliceret'
				)::FacetPubliceretTilsType
			]::FacetPubliceretTilsType[]
	,ARRAY[]::FacetEgenskaberAttrType[]
	,ARRAY[
		 ROW (
			'ansvarlig'::FacetRelationKode,
				null,
			uuidAnsvarlig,
			null,
			null
		) :: FacetRelationType--ARRAY[]::FacetRelationType[]
		 ]
)::FacetRegistreringType;

filter_reg10B:=ROW(
	null --reg base
	,null --ARRAY[]::FacetPubliceretTilsType[]
	,ARRAY[
		ROW(
			null
   			,null --'facetbeskrivelse_C',
   			,null
   			,null --'facetopbygning_C',
   			,null --'facetophavsret_C',
   			,'facetsupplement_C2' --'facetsupplement_C',
   			,NULL --restkilde
            ,NULL --'facetintegrationsdata_C',
   			,null --virkEgenskaberC
			)::FacetEgenskaberAttrType
	]::FacetEgenskaberAttrType[]
	,null --ARRAY[]::FacetRelationType[]
)::FacetRegistreringType;


filter_reg10C:=ROW(
	null --reg base
	,null --ARRAY[]::FacetPubliceretTilsType[]
	, null--ARRAY[]::FacetEgenskaberAttrType[]
	,ARRAY[
		 ROW (
			'ansvarlig'::FacetRelationKode,
				null,
			uuidAnsvarlig,
			null,
			null
		) :: FacetRelationType
	]::FacetRelationType[]
)::FacetRegistreringType;


expected_result10:=array[new_uuidC]::uuid[];
actual_result10:=_as_filter_unauth_facet(array[new_uuidB,new_uuidC]::uuid[],array[filter_reg10A,filter_reg10B,filter_reg10C]::FacetRegistreringType[]);


--RAISE NOTICE 'expected_result10:%',expected_result10 ;
--RAISE NOTICE 'actual_result10:%',actual_result10 ;

RETURN NEXT ok( coalesce(array_length(expected_result10,1),0)=coalesce(array_length(actual_result10,1),0) AND actual_result10 @>expected_result10,'Test #10');


END;
$$;
