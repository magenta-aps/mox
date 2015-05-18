-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_actual_state_search_facet()
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
	facetEgenskab_A FacetAttrEgenskaberType;
	facetPubliceret_A FacetTilsPubliceretType;
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
	facetEgenskab_B FacetAttrEgenskaberType;
	facetPubliceret_B FacetTilsPubliceretType;
	facetRelAnsvarlig_B FacetRelationType;
	facetRelRedaktoer1_B FacetRelationType;
	facetRelRedaktoer2_B FacetRelationType;
	uuidAnsvarlig_B uuid :=uuid_generate_v4();
	uuidRedaktoer1_B uuid :=uuid_generate_v4();
	uuidRedaktoer2_B uuid :=uuid_generate_v4();
	uuidregistrering_B uuid :=uuid_generate_v4();


	search_result1 uuid[];
	search_result2 uuid[];
	
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



facetRelAnsvarlig_A := ROW (
	'Ansvarlig'::FacetRelationKode,
		virkAnsvarlig_A,
	uuidAnsvarlig_A
) :: FacetRelationType
;


facetRelRedaktoer1_A := ROW (
	'Redaktoer'::FacetRelationKode,
		virkRedaktoer1_A,
	uuidRedaktoer1_A
) :: FacetRelationType
;



facetRelRedaktoer2_A := ROW (
	'Redaktoer'::FacetRelationKode,
		virkRedaktoer2_A,
	uuidRedaktoer2_A
) :: FacetRelationType
;


facetPubliceret_A := ROW (
virkPubliceret_A,
'Publiceret'
):: FacetPubliceretType
;


facetEgenskab_A := ROW (
'brugervendt_noegle_text1',
   'facetbeskrivelse_text1',
   'facetplan_text1',
   'facetopbygning_text1',
   'facetophavsret_text1',
   'facetsupplement_text1',
   'retskilde_text1',
   virkEgenskaber_A
) :: FacetAttrEgenskaberType
;


registrering_A := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidregistrering_A,
	'Test Note 4') :: registreringBase
	,
ARRAY[facetPubliceret_A]::FacetTilsPubliceretType[],
ARRAY[facetEgenskab_A]::FacetAttrEgenskaberType[],
ARRAY[facetRelAnsvarlig_A,facetRelRedaktoer1_A,facetRelRedaktoer2_A]
) :: FacetRegistreringType
;

new_uuid_A := actual_state_create_or_import_facet(registrering_A);



--*******************


virkEgenskaber_B :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkAnsvarlig_B :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkRedaktoer1_B :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkRedaktoer2_B :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;



facetRelAnsvarlig_B := ROW (
	'Ansvarlig'::FacetRelationKode,
		virkAnsvarlig_B,
	uuidAnsvarlig_B
) :: FacetRelationType
;


facetRelRedaktoer1_B := ROW (
	'Redaktoer'::FacetRelationKode,
		virkRedaktoer1_B,
	uuidRedaktoer1_B
) :: FacetRelationType
;



facetRelRedaktoer2_B := ROW (
	'Redaktoer'::FacetRelationKode,
		virkRedaktoer2_B,
	uuidRedaktoer2_B
) :: FacetRelationType
;


facetPubliceret_B := ROW (
virkPubliceret_B,
'Publiceret'
):: FacetPubliceretType
;


facetEgenskab_B := ROW (
'brugervendt_noegle_text2',
   'facetbeskrivelse_text2',
   'facetplan_text2',
   'facetopbygning_text2',
   'facetophavsret_text2',
   'facetsupplement_text2',
   'retskilde_text2',
   virkEgenskaber_B
) :: FacetAttrEgenskaberType
;


registrering_B := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidregistrering_B,
	'Test Note 5') :: registreringBase
	,
ARRAY[facetPubliceret_B]::FacetTilsPubliceretType[],
ARRAY[facetEgenskab_B]::FacetAttrEgenskaberType[],
ARRAY[facetRelAnsvarlig_B,facetRelRedaktoer1_B,facetRelRedaktoer2_B]
) :: FacetRegistreringType
;

new_uuid_B := actual_state_create_or_import_facet(registrering_B);


--***********************************
search_result1 :=actual_state_search_facet(
	null,--TOOD ??
	new_uuid_A,
	null--registrering_A Facetregistrering_AType
	);

RETURN NEXT is(
search_result1,
ARRAY[new_uuid_A]::uuid[],
'simple search on single uuid'
);


search_result2 :=actual_state_search_facet(
	null,--TOOD ??
	null,
	null--registrering_A Facetregistrering_AType
	);

RETURN NEXT is(
search_result2,
ARRAY[new_uuid_A,new_uuid_B]::uuid[],
'search null params'
);








--TODO Test for different scenarios









END;
$$;