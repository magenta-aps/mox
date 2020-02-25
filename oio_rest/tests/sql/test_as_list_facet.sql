-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_list_facet()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid uuid;
	new_uuid2 uuid;
	registrering FacetRegistreringType;
	registrering2 FacetRegistreringType;
	virkEgenskaber Virkning;
	virkEgenskaberB Virkning;
	virkEgenskaberC Virkning;
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
	facetEgenskabD FacetEgenskaberAttrType;
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
	actual_facets2 FacetType[];
	expected_facets2 FacetType[];
	actual_facets3 FacetType[];
	expected_facets3 FacetType[];

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
	'[2014-05-13, 2015-05-01)' :: TSTZRANGE,
          '42fbf12c-da1c-4f2e-8ee7-995a4b3dd6cf'::uuid,
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

facetEgenskabA := ROW (
'brugervendt_noegle_A',
   'facetbeskrivelse_A',
   'facetplan_A',
   'facetopbygning_A',
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
   'facetplan_B',
   'facetopbygning_B',
   'facetophavsret_B',
   'facetsupplement_B',
   NULL, --restkilde
   'facetintegrationsdata_B',
   virkEgenskaberB
) :: FacetEgenskaberAttrType
;


registrering := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
ARRAY[facetPubliceret,facetPubliceretB]::FacetPubliceretTilsType[],
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


new_uuid := as_create_or_import_facet(registrering);
new_uuid2 := as_create_or_import_facet(registrering2);

actual_facets1:=as_list_facet(array[new_uuid,new_uuid2]::uuid[],null,null);


select 
(a.registrering).timeperiod into override_timeperiod1
from facet_registrering a
where 
facet_id=new_uuid;

select 
(a.registrering).timeperiod into override_timeperiod2
from facet_registrering a
where 
facet_id=new_uuid2;


expected_facets1:= ARRAY[
		ROW(
			new_uuid,
			ARRAY[
					ROW(
						ROW(
							override_timeperiod1, --this is cheating, but helps the comparison efforts below. (The timeperiod is set during creation/initialization )
							(registrering.registrering).livscykluskode,
							(registrering.registrering).brugerref,
							(registrering.registrering).note 
							)::RegistreringBase
						,registrering.tilsPubliceret
						,registrering.attrEgenskaber
						,registrering.relationer
					)::FacetRegistreringType
				]::FacetRegistreringType[]
			)::FacetType
		,
	ROW(
			new_uuid2,
			ARRAY[
					ROW(
						ROW(
							override_timeperiod2, --this is cheating, but helps the comparison efforts below. (The timeperiod is set during creation/initialization )
							(registrering2.registrering).livscykluskode,
							(registrering2.registrering).brugerref,
							(registrering2.registrering).note 
							)::RegistreringBase
						,registrering2.tilsPubliceret
						,registrering2.attrEgenskaber
						,registrering2.relationer
					)::FacetRegistreringType
			]::FacetRegistreringType[]
			)::FacetType
	]::FacetType[];

select array_agg(a.* order by a.id) from unnest(expected_facets1) as a into expected_facets1;

--raise notice 'list facet expected_facets1:%',to_json(expected_facets1);
--raise notice 'list facet actual_facets1:%',to_json(actual_facets1);


RETURN NEXT is(
	actual_facets1,
	expected_facets1,	
	'list test 1');

/**********************************************************/
BEGIN 


actual_facets2=as_list_facet(array[new_uuid,new_uuid2]::uuid[],null,null,
ARRAY[
 ROW (
	null --reg base
	,null -- publiceret ,
	,ARRAY[
	ROW (
	'brugervendt_noegle_B',
	   null,
	   null,
	   null,
	   null,
	   null,
	   NULL, --restkilde
	   NULL, --'integrationsdata_B',
   	null --virkEgenskaberB
) :: FacetEgenskaberAttrType]::FacetEgenskaberAttrType[]
	,null --relationer 
) :: FacetRegistreringType
]::FacetRegistreringType[]
);

RETURN NEXT ok(false,'as_list_facet test #2: Should throw MO401 exception');
EXCEPTION  
WHEN sqlstate 'MO401' THEN
	RETURN NEXT ok(true,'as_list_facet test #2: Throws MO401 exception (as it should)');
END;


/**********************************************************/


actual_facets3=as_list_facet(array[new_uuid2]::uuid[],null,null,
ARRAY[
 ROW (
	null --reg base
	,null -- publiceret ,
	,ARRAY[
	ROW (
	'brugervendt_noegle_B',
	   null,
	   null,
	   null,
	   null,
	   null,
	   NULL, --restkilde
       NULL, --'integrationsdata_B',
   	null --virkEgenskaberB
) :: FacetEgenskaberAttrType]::FacetEgenskaberAttrType[]
	,null --relationer 
) :: FacetRegistreringType
]::FacetRegistreringType[]
);

expected_facets3:= ARRAY[
	ROW(
			new_uuid2,
			ARRAY[
					ROW(
						ROW(
							override_timeperiod2, --this is cheating, but helps the comparison efforts below. (The timeperiod is set during creation/initialization )
							(registrering2.registrering).livscykluskode,
							(registrering2.registrering).brugerref,
							(registrering2.registrering).note 
							)::RegistreringBase
						,registrering2.tilsPubliceret
						,registrering2.attrEgenskaber
						,registrering2.relationer
					)::FacetRegistreringType
			]::FacetRegistreringType[]
			)::FacetType
	]::FacetType[];

RETURN NEXT is(
	actual_facets3,
	expected_facets3,	
	'facet list test #3');

END;
$$;
