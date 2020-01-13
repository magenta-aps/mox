-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0


--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_read_facet()
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
	facetEgenskab FacetEgenskaberAttrType;
	facetPubliceret FacetPubliceretTilsType;
	facetRelAnsvarlig FacetRelationType;
	facetRelRedaktoer1 FacetRelationType;
	facetRelRedaktoer2 FacetRelationType;
	uuidAnsvarlig uuid :='bf0a1162-69f0-4242-b217-e2d29e06d13a'::uuid;
	uuidRedaktoer1 uuid :='180c0ab2-4210-4b91-94b8-2eff23d3cf10'::uuid;
	uuidRedaktoer2 uuid :='8cbe2b05-34b2-4147-a917-35ed36813e55'::uuid;
	uuidRegistrering uuid :='7ed5e259-78b2-4921-9e4b-d54380be343b'::uuid;
	read_facet1 FacetType;
	expected_facet1 FacetType;
BEGIN


virkEgenskaber :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          '342d9380-56af-4624-a014-7166fb3bbe8e'::uuid,
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkAnsvarlig :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          '26eba752-87fa-4a4a-baed-005f24a13301'::uuid,
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkRedaktoer1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          'fbf707e2-3fe6-43e8-8033-2ca5a24698cd'::uuid,
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkRedaktoer2 :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          'b1bf237a-ce19-48d9-a20d-b50562f56938'::uuid,
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;

virkPubliceret := ROW (
	'[2015-05-18, infinity)' :: TSTZRANGE,
          'b3fbc404-5c94-43f5-aacf-372ab1401967'::uuid,
          'Bruger',
          'NoteEx10'
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


facetEgenskab := ROW (
'brugervendt_noegle_text1',
   'facetbeskrivelse_text1',
   'facetplan_text1',
   'facetopbygning_text1',
   'facetophavsret_text1',
   'facetsupplement_text1',
   'retskilde_text1',
   'integrationsdata_text1',
   virkEgenskaber
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
ARRAY[facetEgenskab]::FacetEgenskaberAttrType[],
ARRAY[facetRelRedaktoer1,facetRelRedaktoer2,facetRelAnsvarlig]
) :: FacetRegistreringType
;

new_uuid := as_create_or_import_facet(registrering);

read_facet1 := as_read_facet(new_uuid,
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
							,registrering.tilsPubliceret
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


--RAISE NOTICE 'read_facet1_json:%',to_json(read_facet1);
--RAISE NOTICE 'expected_facet1_json:%',to_json(expected_facet1);

--TODO Test for different scenarios



END;
$$;
