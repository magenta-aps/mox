-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_actual_state_list_facet()
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
	actual_facets1 FacetType[];
	expected_facets1 FacetType[];
	override_timeperiod1 TSTZRANGE;
	override_timeperiod2 TSTZRANGE;
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

registrering2 := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 27') :: RegistreringBase
	,
ARRAY[facetPubliceretB]::FacetTilsPubliceretType[],
ARRAY[facetEgenskabB]::FacetAttrEgenskaberType[],
ARRAY[facetRelRedaktoer1]
) :: FacetRegistreringType
;


new_uuid := actual_state_create_or_import_facet(registrering);
new_uuid2 := actual_state_create_or_import_facet(registrering2);

select array_agg(a.* order by a.id) from actual_state_list_facet(array[new_uuid,new_uuid2]::uuid[],null,null) as a     into actual_facets1;


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

--raise notice 'expected_facets1:%',expected_facets1;
--raise notice 'actual_facets1:%',actual_facets1;


RETURN NEXT is(
	actual_facets1,
	expected_facets1,	
	'list test 1');

--TODO: Add tests for different scenarios


END;
$$;
