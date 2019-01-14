-- Copyright (C) 2015 Magenta ApS, https://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_update_facet()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid uuid;
	registrering FacetRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaber Virkning;
	virkEgenskaberB Virkning;
	virkEgenskaberC Virkning;
	virkEgenskaberD Virkning;
	virkAnsvarlig Virkning;
	virkansvarligB Virkning;
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
	facetRelAnsvarligB FacetRelationType;
	uuidAnsvarlig uuid := 'b5a4ed96-5120-435e-af96-3fb1e0747536'::uuid;
	uuidAnsvarligB uuid := 'c5a4ed96-5120-435e-af96-3fb1e0747539'::uuid;
	uuidRedaktoer1 uuid :='3768c4e6-28b0-4472-a805-1efe15f21286'::uuid;
	--uuidRedaktoer2 uuid :='e6bb8f99-e3a5-47f5-9ff3-588fcb0638fb'::uuid;
	urnRedaktoer2 text:='urn:isbn:0451450523'::text;
	uuidRegistrering uuid :='e12e46b3-6f67-4bfd-a5bb-768844cbbe71'::uuid;
	update_reg_id bigint;
	update_reg_id2 bigint;
	update_reg_id3 bigint;
	actual_relationer FacetRelationType[];
	actual_publiceret FacetPubliceretTilsType[];
	actual_egenskaber FacetEgenskaberAttrType[];
BEGIN


virkEgenskaber :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkEgenskaberB :=	ROW (
	'[2014-05-13, 2015-01-01)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx7'
          ) :: Virkning
;


virkAnsvarlig :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkAnsvarligB :=	ROW (
	'[2014-03-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx10'
          ) :: Virkning
;

virkRedaktoer1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkRedaktoer2 :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;


virkPubliceret:=	ROW (
	'[2015-05-01, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx8'
          ) :: Virkning
;

virkPubliceretB:=	ROW (
	'[2014-05-13, 2015-05-01)' :: TSTZRANGE,
          uuid_generate_v4(),
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
	null,--uuidRedaktoer2,
	urnRedaktoer2,
	'Aktør' 
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
   'facetopbygning_A',
	'facetophavsret_A',
   'facetplan_A',
   'facetsupplement_A',
   NULL,--'retskilde_text1',
   'integrationsdata_A',
   virkEgenskaber
) :: FacetEgenskaberAttrType
;

facetEgenskabB := ROW (
'brugervendt_noegle_B',
   'facetbeskrivelse_B',
   'facetopbygning_B',
	'facetophavsret_B',
   'facetplan_B',
   'facetsupplement_B',
   NULL, --restkilde
   'integrationsdata_B',
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
ARRAY[facetEgenskabA,facetEgenskabB]::FacetEgenskaberAttrType[],
ARRAY[facetRelAnsvarlig,facetRelRedaktoer1,facetRelRedaktoer2]
) :: FacetRegistreringType
;

new_uuid := as_create_or_import_facet(registrering);

--***************************************
--Update the facet created above


facetRelAnsvarligB := ROW (
	'ansvarlig'::FacetRelationKode,
		virkAnsvarligB,
	uuidAnsvarligB,
	null,
	'Aktør'
) :: FacetRelationType
;

virkEgenskaberC :=	ROW (
	'[2015-01-13, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx20'
          ) :: Virkning
;

virkEgenskaberD :=	ROW (
	'[2013-06-30, 2014-06-01)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx7'
          ) :: Virkning
;

facetEgenskabC := ROW (
   'brugervendt_noegle_A',
   NULL, --'facetbeskrivelse_text1',
   NULL,--'facetopbygning_text1',
	'facetophavsret_C',
   'facetplan_C',
   'facetsupplement_C',
   'retskilde_C',
   'integrationsdata_C',
   virkEgenskaberC
) :: FacetEgenskaberAttrType
;

facetEgenskabD := ROW (
'brugervendt_noegle_D',
   'facetbeskrivelse_D',
   'facetopbygning_D',
   'facetophavsret_D',
   NULL,-- 'facetplan_D',
   'facetsupplement_D',
   NULL, --restkilde
   'integrationsdata_D',
   virkEgenskaberD
) :: FacetEgenskaberAttrType
;

virkPubliceretC:=	ROW (
	'[2015-01-01, 2015-05-01]' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx10'
          ) :: Virkning
;



facetPubliceretC := ROW (
virkPubliceretC,
''::FacetPubliceretTils
):: FacetPubliceretTilsType
;



update_reg_id:=as_update_facet(
  new_uuid, uuid_generate_v4(),'Test update'::text,
  'Rettet'::Livscykluskode,          
  array[facetEgenskabC,facetEgenskabD]::FacetEgenskaberAttrType[],
  array[facetPubliceretC]::FacetPubliceretTilsType[],
  array[facetRelAnsvarligB]::FacetRelationType[]
	);


SELECT
array_agg(
			ROW (
					a.rel_type,
					a.virkning,
					a.rel_maal_uuid,
					a.rel_maal_urn,
					a.objekt_type 
				):: FacetRelationType
		) into actual_relationer
FROM facet_relation a
JOIN facet_registrering as b on a.facet_registrering_id=b.id
WHERE b.id=update_reg_id
;

RETURN NEXT is(
	actual_relationer,
	ARRAY[facetRelAnsvarligB,facetRelRedaktoer1,facetRelRedaktoer2]
,'relations carried over'); --ok, if all relations are present.


SELECT
array_agg(
			ROW (
					a.virkning,
					a.publiceret
				):: FacetPubliceretTilsType
		) into actual_publiceret
FROM facet_tils_publiceret a
JOIN facet_registrering as b on a.facet_registrering_id=b.id
WHERE b.id=update_reg_id
;



RETURN NEXT is(
	actual_publiceret,
ARRAY[
	facetPubliceretC,
	ROW(
		ROW (
				TSTZRANGE('2015-05-01','infinity','()')
				,(facetPubliceret.virkning).AktoerRef
				,(facetPubliceret.virkning).AktoerTypeKode
				,(facetPubliceret.virkning).NoteTekst
			) :: Virkning
		,facetPubliceret.publiceret
		)::FacetPubliceretTilsType,
	ROW(
		ROW (
				TSTZRANGE('2014-05-13','2015-01-01','[)')
				,(facetPubliceretB.virkning).AktoerRef
				,(facetPubliceretB.virkning).AktoerTypeKode
				,(facetPubliceretB.virkning).NoteTekst
			) :: Virkning
		,facetPubliceretB.publiceret
		)::FacetPubliceretTilsType
]::FacetPubliceretTilsType[]
,'publiceret value updated');


RETURN NEXT set_eq( 'SELECT

			ROW (
					a.brugervendtnoegle,
					a.beskrivelse,
					a.opbygning,
					a.ophavsret,
   					a.plan,
   					a.supplement,
   					a.retskilde,
					a.integrationsdata,
					a.virkning
				):: FacetEgenskaberAttrType
		
FROM  facet_attr_egenskaber a
JOIN facet_registrering as b on a.facet_registrering_id=b.id
WHERE b.id=' || update_reg_id::text
,   
ARRAY[
		ROW(
				facetEgenskabD.brugervendtnoegle,
   				facetEgenskabD.beskrivelse,
   				facetEgenskabD.opbygning,
   				facetEgenskabD.ophavsret,
   				NULL, --facetEgenskabD.plan,
   				facetEgenskabD.supplement,
   				facetEgenskabD.retskilde,
   				facetEgenskabD.integrationsdata,
					ROW(
						TSTZRANGE('2013-06-30','2014-05-13','[)'),
						(facetEgenskabD.virkning).AktoerRef,
						(facetEgenskabD.virkning).AktoerTypeKode,
						(facetEgenskabD.virkning).NoteTekst
						)::virkning
			) ::FacetEgenskaberAttrType
		,
		ROW(
			facetEgenskabD.brugervendtnoegle,
   				facetEgenskabD.beskrivelse,
   				facetEgenskabD.opbygning,
   				facetEgenskabD.ophavsret,
   				facetEgenskabB.plan, --NOTICE
   				facetEgenskabD.supplement,
   				NULL, --notice
   				facetEgenskabD.integrationsdata,
   				ROW(
						TSTZRANGE('2014-05-13','2014-06-01','[)'),
						(facetEgenskabD.virkning).AktoerRef,
						(facetEgenskabD.virkning).AktoerTypeKode,
						(facetEgenskabD.virkning).NoteTekst
						)::virkning
		)::FacetEgenskaberAttrType
		,
		ROW(
			facetEgenskabB.brugervendtnoegle,
   				facetEgenskabB.beskrivelse,
   				facetEgenskabB.opbygning,
   				facetEgenskabB.ophavsret,
   				facetEgenskabB.plan,
   				facetEgenskabB.supplement,
   				facetEgenskabB.retskilde,
   				facetEgenskabB.integrationsdata,
					ROW(
						TSTZRANGE('2014-06-01','2015-01-01','[)'),
						(facetEgenskabB.virkning).AktoerRef,
						(facetEgenskabB.virkning).AktoerTypeKode,
						(facetEgenskabB.virkning).NoteTekst
						)::virkning
			)::FacetEgenskaberAttrType
		,
		ROW(
			facetEgenskabC.brugervendtnoegle,
   				facetEgenskabC.beskrivelse,
   				facetEgenskabC.opbygning,
   				facetEgenskabC.ophavsret,
   				facetEgenskabC.plan,
   				facetEgenskabC.supplement,
   				facetEgenskabC.retskilde,
   				facetEgenskabC.integrationsdata,
					ROW(
						TSTZRANGE('2015-01-13','2015-05-12','[)'),
						(facetEgenskabC.virkning).AktoerRef,
						(facetEgenskabC.virkning).AktoerTypeKode,
						(facetEgenskabC.virkning).NoteTekst
						)::virkning
			)::FacetEgenskaberAttrType
		,
		ROW(
			facetEgenskabA.brugervendtnoegle, --notice
   				facetEgenskabA.beskrivelse, --notice
   				facetEgenskabA.opbygning, --notice
   				facetEgenskabC.ophavsret,
   				facetEgenskabC.plan,
   				facetEgenskabC.supplement,
   				facetEgenskabC.retskilde,
   				facetEgenskabC.integrationsdata,
					ROW(
						TSTZRANGE('2015-05-12','infinity','[)'),
						(facetEgenskabC.virkning).AktoerRef,
						(facetEgenskabC.virkning).AktoerTypeKode,
						(facetEgenskabC.virkning).NoteTekst
						)::virkning
			)::FacetEgenskaberAttrType

	]::FacetEgenskaberAttrType[]
    ,    'egenskaber updated' );

/*********************************************/
--Test if providing auth criteria will trigger exception as expected
BEGIN

update_reg_id2:=as_update_facet(
  new_uuid, '592fcdea-0f88-4af1-b2b5-990ae4787ecd'::uuid,'Test update 2'::text,
  'Rettet'::Livscykluskode,          
  array[facetEgenskabC,facetEgenskabD]::FacetEgenskaberAttrType[],
  array[]::FacetPubliceretTilsType[],
  array[facetRelAnsvarligB]::FacetRelationType[]
  ,null --lostUpdatePreventionTZ
  , ARRAY [ ROW (
	 	null --reg base
	 	,null --states
	 	,ARRAY[
		 	ROW (
			null --'brugervendt_noegle_B',
		   ,null--'facetbeskrivelse_B',
		   ,null --'facetopbygning_B',
			,null--'facetophavsret_BC',
		   , 'facetplan_343434'
		   ,null --'facetsupplement_B',
		   ,NULL --restkilde
		   ,NULL --'integrationsdata_B',
		   ,null --virkning
			) :: FacetEgenskaberAttrType
	 	]::FacetEgenskaberAttrType[] 
	 	,null --relationer
	 	)::FacetRegistreringType]:: FacetRegistreringType[]
	);

RETURN NEXT ok(false,'as_update_facet test auth criteria#1: Should throw MO401 exception');
EXCEPTION  
WHEN sqlstate 'MO401' THEN
	RETURN NEXT ok(true,'as_update_facet test auth criteria#1: Throws MO401 exception (as it should)');
END;

/*********************************************/
--Test if  providing fullfilled auth criteria will NOT trigger exception as expected


update_reg_id3:=as_update_facet(
  new_uuid, '592fcdea-0f88-4af1-b2b5-990ae4787ecd'::uuid,'Test update 3'::text,
  'Rettet'::Livscykluskode,          
  array[facetEgenskabC,facetEgenskabD]::FacetEgenskaberAttrType[],
  array[]::FacetPubliceretTilsType[],
  array[facetRelAnsvarligB]::FacetRelationType[]
  ,null --lostUpdatePreventionTZ
  , ARRAY [ ROW (
	 	null --reg base
	 	,null --states
	 	,ARRAY[
		 	ROW (
				null --'brugervendt_noegle_B',
			   ,null --'facetbeskrivelse_B',
			   ,null--'facetopbygning_B',
				,'facetophavsret_C'
			   ,null --'facetplan_B',
			   ,null --'facetsupplement_B',
			   ,NULL --restkilde
			   ,NULL --'integrationsdata_B',
			   ,null --virkEgenskaberB
			) :: FacetEgenskaberAttrType
	 	]::FacetEgenskaberAttrType[] 
	 	,null --relationer
	 	)::FacetRegistreringType]:: FacetRegistreringType[]
	);

RETURN NEXT ok(update_reg_id3<>update_reg_id,'No expetion thrown when access criteria is met');


END;
$$;
