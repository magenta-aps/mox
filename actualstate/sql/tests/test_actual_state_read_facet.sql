-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_actual_state_read_facet()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid uuid;
	registrering FacetRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaber Virkning;
	virkAnsvarlig Virkning;
	virkRedaktoer1 Virkning;
	virkRedaktoer2 Virkning;
	virkPubliceret Virkning;
	facetEgenskab FacetAttrEgenskaberType;
	facetPubliceret FacetTilsPubliceretType;
	facetRelAnsvarlig FacetRelationType;
	facetRelRedaktoer1 FacetRelationType;
	facetRelRedaktoer2 FacetRelationType;
	uuidAnsvarlig uuid :=uuid_generate_v4();
	uuidRedaktoer1 uuid :=uuid_generate_v4();
	uuidRedaktoer2 uuid :=uuid_generate_v4();
	uuidRegistrering uuid :=uuid_generate_v4();
	read_facet1 FacetType;
	expected_facet1 FacetType;
BEGIN


virkEgenskaber :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
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

virkPubliceret := ROW (
	'[2015-05-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx10'
) :: Virkning
;


facetRelAnsvarlig := ROW (
	'Ansvarlig'::FacetRelationKode,
		virkAnsvarlig,
	uuidAnsvarlig
) :: FacetRelationType
;


facetRelRedaktoer1 := ROW (
	'Redaktoer'::FacetRelationKode,
		virkRedaktoer1,
	uuidRedaktoer1
) :: FacetRelationType
;



facetRelRedaktoer2 := ROW (
	'Redaktoer'::FacetRelationKode,
		virkRedaktoer2,
	uuidRedaktoer2
) :: FacetRelationType
;


facetPubliceret := ROW (
virkPubliceret,
'Publiceret'
):: FacetTilsPubliceretType
;


facetEgenskab := ROW (
'brugervendt_noegle_text1',
   'facetbeskrivelse_text1',
   'facetplan_text1',
   'facetopbygning_text1',
   'facetophavsret_text1',
   'facetsupplement_text1',
   'retskilde_text1',
   virkEgenskaber
) :: FacetAttrEgenskaberType
;


registrering := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
ARRAY[facetPubliceret]::FacetTilsPubliceretType[],
ARRAY[facetEgenskab]::FacetAttrEgenskaberType[],
ARRAY[facetRelAnsvarlig,facetRelRedaktoer1,facetRelRedaktoer2]
) :: FacetRegistreringType
;

new_uuid := actual_state_create_or_import_facet(registrering);

read_facet1 := actual_state_read_facet(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

expected_facet1 :=
				ROW(
					new_uuid,
					ARRAY[
						ROW(
							ROW(
								((read_facet1.registrering[1]).registrering).timeperiod, --this is cheating, but helps the comparison efforts below. (The timeperiod is set during creation/initialization )
								(registrering.registrering).livscykluskode,
								(registrering.registrering).brugerref,
								(registrering.registrering).note 
								)::RegistreringBase
							,registrering.tilsPubliceretStatus
							,registrering.attrEgenskaber
							,registrering.relationer
						)::FacetRegistreringType
					]::FacetRegistreringType[]
			)::FacetType
;

RETURN NEXT is(
read_facet1,
expected_facet1,
'simple search test 1'
);


--TODO Test for different scenarios



END;
$$;