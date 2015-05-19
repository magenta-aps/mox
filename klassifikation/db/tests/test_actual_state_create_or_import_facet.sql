-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_actual_state_create_or_import_facet()
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
	actual_publiceret_virk virkning;
	actual_publiceret_status FacetTilsPubliceretStatus;
	actual_publiceret FacetTilsPubliceretType;
	actual_relationer FacetRelationType[];
	uuid_to_import uuid :=uuid_generate_v4();
	uuid_returned_from_import uuid;

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
	 	a.status into actual_publiceret_status
FROM facet_tils_publiceret a 
JOIN facet_registrering as b on a.facet_registrering_id=b.id
WHERE b.facet_id=new_uuid
;

actual_publiceret:=ROW(
	actual_publiceret_virk,
	actual_publiceret_status
)::FacetTilsPubliceretType ;


RETURN NEXT is(actual_publiceret.virkning,facetPubliceret.virkning,'publiceret virkning');
RETURN NEXT is(actual_publiceret.status,facetPubliceret.status,'publicaret status');

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
WHERE b.facet_id=new_uuid
;

RETURN NEXT is(
	actual_relationer,
	ARRAY[facetRelAnsvarlig,facetRelRedaktoer1,facetRelRedaktoer2]
,'relations present');

--****************************
--test an import operation
uuid_returned_from_import:=actual_state_create_or_import_facet(registrering,uuid_to_import);

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




END;
$$;