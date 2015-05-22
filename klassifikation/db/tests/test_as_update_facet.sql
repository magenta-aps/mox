-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
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
	virkRedaktoer1 Virkning;
	virkRedaktoer2 Virkning;
	virkPubliceret Virkning;
	virkPubliceretB Virkning;
	virkPubliceretC Virkning;
	facetEgenskabA FacetAttrEgenskaberType;
	facetEgenskabB FacetAttrEgenskaberType;
	facetEgenskabC FacetAttrEgenskaberType;
	facetEgenskabD FacetAttrEgenskaberType;
	facetPubliceret FacetTilsPubliceretType;
	facetPubliceretB FacetTilsPubliceretType;
	facetPubliceretC FacetTilsPubliceretType;
	facetRelAnsvarlig FacetRelationType;
	facetRelRedaktoer1 FacetRelationType;
	facetRelRedaktoer2 FacetRelationType;
	uuidAnsvarlig uuid :=uuid_generate_v4();
	uuidRedaktoer1 uuid :=uuid_generate_v4();
	uuidRedaktoer2 uuid :=uuid_generate_v4();
	uuidRegistrering uuid :=uuid_generate_v4();
	update_reg_id bigint;
	actual_relationer FacetRelationType[];
	actual_publiceret FacetTilsPubliceretType[];
	actual_egenskaber FacetAttrEgenskaberType[];
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
	uuidAnsvarlig
) :: FacetRelationType
;


facetRelRedaktoer1 := ROW (
	'redaktoerer'::FacetRelationKode,
		virkRedaktoer1,
	uuidRedaktoer1
) :: FacetRelationType
;



facetRelRedaktoer2 := ROW (
	'redaktoerer'::FacetRelationKode,
		virkRedaktoer2,
	uuidRedaktoer2
) :: FacetRelationType
;


facetPubliceret := ROW (
virkPubliceret,
'Publiceret'
):: FacetTilsPubliceretType
;

facetPubliceretB := ROW (
virkPubliceretB,
'IkkePubliceret'
):: FacetTilsPubliceretType
;

facetEgenskabA := ROW (
'brugervendt_noegle_A',
   'facetbeskrivelse_A',
   'facetplan_A',
   'facetopbygning_A',
   'facetophavsret_A',
   'facetsupplement_A',
   NULL,--'retskilde_text1',
   virkEgenskaber
) :: FacetAttrEgenskaberType
;

facetEgenskabB := ROW (
'brugervendt_noegle_B',
   'facetbeskrivelse_B',
   'facetplan_B',
   'facetopbygning_B',
   'facetophavsret_B',
   'facetsupplement_B',
   NULL, --restkilde
   virkEgenskaberB
) :: FacetAttrEgenskaberType
;


registrering := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
ARRAY[facetPubliceret,facetPubliceretB]::FacetTilsPubliceretType[],
ARRAY[facetEgenskabA,facetEgenskabB]::FacetAttrEgenskaberType[],
ARRAY[facetRelAnsvarlig,facetRelRedaktoer1,facetRelRedaktoer2]
) :: FacetRegistreringType
;

new_uuid := as_create_or_import_facet(registrering);

--***************************************
--Update the facet created above

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
   NULL,--'brugervendt_noegle_text1',
   NULL, --'facetbeskrivelse_text1',
   'facetplan_C',
   NULL,--'facetopbygning_text1',
   'facetophavsret_C',
   'facetsupplement_C',
   'retskilde_C',
   virkEgenskaberC
) :: FacetAttrEgenskaberType
;

facetEgenskabD := ROW (
'brugervendt_noegle_D',
   'facetbeskrivelse_D',
   NULL,-- 'facetplan_D',
   'facetopbygning_D',
   'facetophavsret_D',
   'facetsupplement_D',
   NULL, --restkilde
   virkEgenskaberD
) :: FacetAttrEgenskaberType
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
''::FacetTilsPubliceret
):: FacetTilsPubliceretType
;



update_reg_id:=as_update_facet(
  new_uuid, uuid_generate_v4(),'Test update'::text,
  'Rettet'::Livscykluskode,          
  array[facetEgenskabC,facetEgenskabD]::FacetAttrEgenskaberType[],
  array[facetPubliceretC]::FacetTilsPubliceretType[],
  array[facetRelAnsvarlig]::FacetRelationType[]
	);


SELECT
array_agg(
			ROW (
					a.rel_type,
					a.virkning,
					a.rel_maal 
				):: FacetRelationType
		) into actual_relationer
FROM facet_relation a
JOIN facet_registrering as b on a.facet_registrering_id=b.id
WHERE b.id=update_reg_id
;

RETURN NEXT is(
	actual_relationer,
	ARRAY[facetRelAnsvarlig,facetRelRedaktoer1,facetRelRedaktoer2]
,'relations carried over'); --ok, if all relations are present.


SELECT
array_agg(
			ROW (
					a.virkning,
					a.publiceret
				):: FacetTilsPubliceretType
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
		)::FacetTilsPubliceretType,
	ROW(
		ROW (
				TSTZRANGE('2014-05-13','2015-01-01','[)')
				,(facetPubliceretB.virkning).AktoerRef
				,(facetPubliceretB.virkning).AktoerTypeKode
				,(facetPubliceretB.virkning).NoteTekst
			) :: Virkning
		,facetPubliceretB.publiceret
		)::FacetTilsPubliceretType
]::FacetTilsPubliceretType[]
,'publiceret value updated');


RETURN NEXT set_eq( 'SELECT

			ROW (
					a.brugervendt_noegle,
   					a.facetbeskrivelse,
   					a.facetplan,
   					a.facetopbygning,
   					a.facetophavsret,
   					a.facetsupplement,
   					a.retskilde,
					a.virkning
				):: FacetAttrEgenskaberType
		
FROM  facet_attr_egenskaber a
JOIN facet_registrering as b on a.facet_registrering_id=b.id
WHERE b.id=' || update_reg_id::text
,   
ARRAY[
		ROW(
				facetEgenskabD.brugervendt_noegle,
   				facetEgenskabD.facetbeskrivelse,
   				NULL, --facetEgenskabD.facetplan,
   				facetEgenskabD.facetopbygning,
   				facetEgenskabD.facetophavsret,
   				facetEgenskabD.facetsupplement,
   				facetEgenskabD.retskilde,
					ROW(
						TSTZRANGE('2013-06-30','2014-05-13','[)'),
						(facetEgenskabD.virkning).AktoerRef,
						(facetEgenskabD.virkning).AktoerTypeKode,
						(facetEgenskabD.virkning).NoteTekst
						)::virkning
			) ::FacetAttrEgenskaberType
		,
		ROW(
			facetEgenskabD.brugervendt_noegle,
   				facetEgenskabD.facetbeskrivelse,
   				facetEgenskabB.facetplan, --NOTICE
   				facetEgenskabD.facetopbygning,
   				facetEgenskabD.facetophavsret,
   				facetEgenskabD.facetsupplement,
   				NULL, --notice
   				ROW(
						TSTZRANGE('2014-05-13','2014-06-01','[)'),
						(facetEgenskabD.virkning).AktoerRef,
						(facetEgenskabD.virkning).AktoerTypeKode,
						(facetEgenskabD.virkning).NoteTekst
						)::virkning
		)::FacetAttrEgenskaberType
		,
		ROW(
			facetEgenskabB.brugervendt_noegle,
   				facetEgenskabB.facetbeskrivelse,
   				facetEgenskabB.facetplan,
   				facetEgenskabB.facetopbygning,
   				facetEgenskabB.facetophavsret,
   				facetEgenskabB.facetsupplement,
   				facetEgenskabB.retskilde,
					ROW(
						TSTZRANGE('2014-06-01','2015-01-01','[)'),
						(facetEgenskabB.virkning).AktoerRef,
						(facetEgenskabB.virkning).AktoerTypeKode,
						(facetEgenskabB.virkning).NoteTekst
						)::virkning
			)::FacetAttrEgenskaberType
		,
		ROW(
			facetEgenskabC.brugervendt_noegle,
   				facetEgenskabC.facetbeskrivelse,
   				facetEgenskabC.facetplan,
   				facetEgenskabC.facetopbygning,
   				facetEgenskabC.facetophavsret,
   				facetEgenskabC.facetsupplement,
   				facetEgenskabC.retskilde,
					ROW(
						TSTZRANGE('2015-01-13','2015-05-12','[)'),
						(facetEgenskabC.virkning).AktoerRef,
						(facetEgenskabC.virkning).AktoerTypeKode,
						(facetEgenskabC.virkning).NoteTekst
						)::virkning
			)::FacetAttrEgenskaberType
		,
		ROW(
			facetEgenskabA.brugervendt_noegle, --notice
   				facetEgenskabA.facetbeskrivelse, --notice
   				facetEgenskabC.facetplan,
   				facetEgenskabA.facetopbygning, --notice
   				facetEgenskabC.facetophavsret,
   				facetEgenskabC.facetsupplement,
   				facetEgenskabC.retskilde,
					ROW(
						TSTZRANGE('2015-05-12','infinity','[)'),
						(facetEgenskabC.virkning).AktoerRef,
						(facetEgenskabC.virkning).AktoerTypeKode,
						(facetEgenskabC.virkning).NoteTekst
						)::virkning
			)::FacetAttrEgenskaberType

	]::FacetAttrEgenskaberType[]
    ,    'egenskaber updated' );


--TODO: Add tests for different scenarios





END;
$$;