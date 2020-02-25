-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_create_or_import_facet()
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
	uuidAnsvarlig uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	uuidRedaktoer1 uuid :='b7160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;
	--uuidRedaktoer2 uuid :='08533179-fedb-4aa7-8902-ab34a219eed9'::uuid;
	urnRedaktoer2 text:='urn:isbn:0451450523'::text;
	uuidRegistrering uuid :='1f368584-4c3e-4ba4-837b-da2b1eee37c9'::uuid;
	actual_publiceret_virk virkning;
	actual_publiceret_value FacetPubliceretTils;
	actual_publiceret FacetPubliceretTilsType;
	actual_relationer FacetRelationType[];
	uuid_to_import uuid :='a1819cce-043b-447f-ba5e-92e6a75df918'::uuid;
	uuid_to_import2 uuid :='90819cce-043b-447f-ba1e-92e6a75df929'::uuid;
	uuid_returned_from_import uuid;
	uuid_returned_from_import2 uuid;
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
	'ansvarlig'::FacetRelationKode,
		virkAnsvarlig,
	uuidAnsvarlig,
	null,
	'Aktør'
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
	null,
	urnRedaktoer2,
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
ARRAY[facetRelAnsvarlig,facetRelRedaktoer1,facetRelRedaktoer2]
) :: FacetRegistreringType
;


new_uuid := as_create_or_import_facet(registrering);

RETURN NEXT is(
	ARRAY(
		SELECT
			id
		FROM
		facet
		where id=new_uuid
		),
	ARRAY[new_uuid]::uuid[]
);


SELECT
	(a.registrering).* into actual_registrering
FROM
facet_registrering a
where facet_id=new_uuid
;


RETURN NEXT is(actual_registrering.livscykluskode,(registrering.registrering).livscykluskode,'registrering livscykluskode');
RETURN NEXT is(actual_registrering.brugerref,(registrering.registrering).brugerref,'registrering brugerref');
RETURN NEXT is(actual_registrering.note,(registrering.registrering).note,'registrering note');
RETURN NEXT ok(upper(actual_registrering.timeperiod)='infinity'::timestamp with time zone,'registrering timeperiod upper is infinity');
RETURN NEXT ok(lower(actual_registrering.timeperiod) <clock_timestamp(),'registrering timeperiod before now');
RETURN NEXT ok(lower(actual_registrering.timeperiod) > clock_timestamp() - 3 * interval '1 second',' registrering timeperiod later than 3 secs' );

SELECT
	 	(a.virkning).* into actual_publiceret_virk
FROM facet_tils_publiceret a 
JOIN facet_registrering as b on a.facet_registrering_id=b.id
WHERE b.facet_id=new_uuid
;

SELECT
	 	a.publiceret into actual_publiceret_value
FROM facet_tils_publiceret a 
JOIN facet_registrering as b on a.facet_registrering_id=b.id
WHERE b.facet_id=new_uuid
;

actual_publiceret:=ROW(
	actual_publiceret_virk,
	actual_publiceret_value
)::FacetPubliceretTilsType ;


RETURN NEXT is(actual_publiceret.virkning,facetPubliceret.virkning,'publiceret virkning');
RETURN NEXT is(actual_publiceret.publiceret,facetPubliceret.publiceret,'publiceret value');

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
WHERE b.facet_id=new_uuid
;

RETURN NEXT is(
	actual_relationer,
	ARRAY[facetRelAnsvarlig,facetRelRedaktoer1,facetRelRedaktoer2]
,'relations present');

--****************************
--test an import operation
uuid_returned_from_import:=as_create_or_import_facet(registrering,uuid_to_import);

RETURN NEXT is(
	uuid_returned_from_import,
	uuid_to_import,
	'import returns uuid'
	);

RETURN NEXT is(
	ARRAY(
		SELECT
			id
		FROM
		facet
		where id=uuid_to_import
		),
	ARRAY[uuid_to_import]::uuid[]
,'import creates new facet.');

--****************************
--test that an exception is thrown when stipulated access criteria is not met


BEGIN
uuid_returned_from_import2:=as_create_or_import_facet(registrering,uuid_to_import2,
	ARRAY[
	ROW(
		null,
		array [
			ROW (
			null,
			'IkkePubliceret'
			):: FacetPubliceretTilsType
		]
		,null
		,null
		)
	::FacetRegistreringType
		]
	);


RETURN NEXT ok(false,'as_create_or_import test auth criteria#1: Should throw MO401 exception');
EXCEPTION  
WHEN sqlstate 'MO401' THEN
	RETURN NEXT ok(true,'as_create_or_import test auth criteria#1: Throws MO401 exception (as it should)');
END;

--****************************
--test that an exception is not thrown when stipulated access criteria is met

uuid_returned_from_import2:=as_create_or_import_facet(registrering,uuid_to_import2,
	ARRAY[
	ROW(
		null,
		array [
			ROW (
			null,
			'Publiceret'
			):: FacetPubliceretTilsType
		]
		,null
		,null
		)
	::FacetRegistreringType
		]
	);

RETURN NEXT is (uuid_returned_from_import2,uuid_to_import2,'No exception thrown, when criteria is met invoking import.');



END;
$$;
