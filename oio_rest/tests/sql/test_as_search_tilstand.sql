-- SPDX-FileCopyrightText: 2016-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_search_tilstand()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid1 uuid;
	new_uuid2 uuid;
	new_uuid3 uuid;
	registrering tilstandRegistreringType;
	registrering2 tilstandRegistreringType;
	registrering3 tilstandRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaber Virkning;
	virkTilstandsobjekt Virkning;
	virkTilstandsvaerdi1 Virkning;
	virkTilstandsvaerdi2 Virkning;
	virkTilstandskvalitet1 Virkning;
	virkTilstandskvalitet2 Virkning;
	virkPubliceret Virkning;
	virkStatus Virkning;
	tilstandEgenskab tilstandEgenskaberAttrType;
	tilstandStatus tilstandStatusTilsType;
	tilstandPubliceret tilstandPubliceretTilsType;
	tilstandRelTilstandsobjekt tilstandRelationType;
	tilstandRelTilstandsvaerdi1 tilstandRelationType;
	tilstandRelTilstandsvaerdi2 tilstandRelationType;
	tilstandRelTilstandskvalitet1 tilstandRelationType;
	tilstandRelTilstandskvalitet2 tilstandRelationType;
	
	uuidTilstandsobjekt uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	--uuidTilstandsvaerdi1 uuid :='b7160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;


	uuidTilstandsvaerdi2 uuid :='08533179-fedb-4aa7-8902-ab34a219eed9'::uuid;
	--urnTilstandsvaerdi2 text:='urn:isbn:0451450523'::text;
	uuidTilstandskvalitet1 uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09d'::uuid;
	uuidTilstandskvalitet2 uuid :='28533179-fedb-4aa7-8902-ab34a219eed1'::uuid;
	uuidRegistrering uuid :='1f368584-4c3e-4ba4-837b-da2b1eee37c9'::uuid;
	actual_publiceret_virk virkning;
	actual_publiceret_value tilstandStatusTils;
	actual_publiceret tilstandStatusTilsType;
	actual_relationer tilstandRelationType[];
	uuid_to_import uuid :='a1819cce-043b-447f-ba5e-92e6a75df918'::uuid;
	uuid_returned_from_import uuid;
	read_Tilstand1 TilstandType;
	expected_tilstand1 TilstandType;
	read_Tilstand2 TilstandType;
	expected_tilstand2 TilstandType;

	expected_search_res_1 uuid[];
	expected_search_res_2 uuid[];
	expected_search_res_3 uuid[];
	expected_search_res_4 uuid[];

	actual_search_res_1 uuid[];
	actual_search_res_2 uuid[];
	actual_search_res_3 uuid[];
	actual_search_res_4 uuid[];
BEGIN


virkEgenskaber :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkTilstandsobjekt :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkTilstandsvaerdi1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkTilstandsvaerdi2 :=	ROW (
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

virkstatus := ROW (
	'[2016-12-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx20'
) :: Virkning
;

virkTilstandskvalitet1 :=	ROW (
	'[2015-04-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx23'
          ) :: Virkning
;


virkTilstandskvalitet2 :=	ROW (
	'[2015-06-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx12'
          ) :: Virkning
;

tilstandRelTilstandsobjekt := ROW (
	'tilstandsobjekt'::tilstandRelationKode
	,virkTilstandsobjekt
	,uuidTilstandsobjekt
	,null
	,'Person'
	,900 --NOTICE: Should be replace in by import function
	,null --TilstandVaerdiRelationAttrType
) :: tilstandRelationType
;


tilstandRelTilstandsvaerdi1 := ROW (
	'tilstandsvaerdi'::tilstandRelationKode,
		virkTilstandsvaerdi1,
	null,
	null,
	null
	,768 --NOTICE: Should be replace in by import function
	,ROW(true,'82')::TilstandVaerdiRelationAttrType
) :: tilstandRelationType
;



tilstandRelTilstandsvaerdi2 := ROW (
	'tilstandsvaerdi'::tilstandRelationKode,
		virkTilstandsvaerdi2,
	uuidTilstandsvaerdi2,
	null,--urnTilstandsvaerdi2
	'Klasse'
	,800 --NOTICE: Should be replace in by import function
	, null --TilstandVaerdiRelationAttrType
) :: tilstandRelationType
;



tilstandRelTilstandskvalitet1 := ROW (
	'tilstandskvalitet'::tilstandRelationKode,
		virkTilstandskvalitet1,
	uuidTilstandskvalitet1,
	null,
	'Klasse'
	,7268 --NOTICE: Should be replace in by import function
	, null --TilstandVaerdiRelationAttrType
) :: tilstandRelationType
;



tilstandRelTilstandskvalitet2 := ROW (
	'tilstandskvalitet'::tilstandRelationKode,
		virkTilstandskvalitet2,
	uuidTilstandskvalitet2,
	null,
	'Klasse'
	,3 --NOTICE: Should be replace in by import function
	,null --TilstandVaerdiRelationAttrType
) :: tilstandRelationType
;



tilstandStatus := ROW (
virkStatus,
'Aktiv'::TilstandStatusTils
):: tilstandStatusTilsType
;

tilstandPubliceret := ROW (
virkPubliceret,
'Normal'::TilstandPubliceretTils
)::tilstandPubliceretTilsType;

tilstandEgenskab := ROW (
'brugervendtnoegle_tilstand_1' --text, 
,'beskrivelse_tilstand_fælles'-- text,
,'integrationsdata_1'
,virkEgenskaber
) :: tilstandEgenskaberAttrType
;


registrering := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
	ARRAY[tilstandStatus]::tilstandStatusTilsType[],
	ARRAY[tilstandPubliceret]::TilstandPubliceretTilsType[],
ARRAY[tilstandEgenskab]::tilstandEgenskaberAttrType[],
ARRAY[tilstandRelTilstandsobjekt,tilstandRelTilstandsvaerdi1,tilstandRelTilstandsvaerdi2,tilstandRelTilstandskvalitet1,tilstandRelTilstandskvalitet2]) :: tilstandRegistreringType
;


--raise notice 'to be written tilstand 1:%',to_json(registrering);

new_uuid1 := as_create_or_import_tilstand(registrering);


RETURN NEXT ok(true,'No errors running as_create_or_import_tilstand1');

/*********************************/

registrering2:=ROW (
	ROW(
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 5') :: RegistreringBase
	,
	ARRAY[tilstandStatus]::tilstandStatusTilsType[],
	ARRAY[tilstandPubliceret]::TilstandPubliceretTilsType[],
ARRAY[
ROW (
'brugervendtnoegle_tilstand_2' --text, 
,'beskrivelse_tilstand_fælles'-- text,
,'integrationsdata_2'-- text,
,ROW( '[2016-01-01, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
) :: tilstandEgenskaberAttrType ]::tilstandEgenskaberAttrType[],
ARRAY[tilstandRelTilstandsobjekt]) :: tilstandRegistreringType

;

new_uuid2 := as_create_or_import_tilstand(registrering2);

RETURN NEXT ok(true,'No errors running as_create_or_import_tilstand2');

/*********************************/
registrering3:=ROW (
	ROW(
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 6' ):: RegistreringBase
	,
	ARRAY[tilstandStatus]::tilstandStatusTilsType[],
	ARRAY[tilstandPubliceret]::TilstandPubliceretTilsType[],
ARRAY[
ROW (
'brugervendtnoegle_tilstand_3' --text, 
,'beskrivelse_tilstand_fælles'-- text,
,'integrationsdata_3'-- text,
,ROW( '[2016-06-01, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
) :: tilstandEgenskaberAttrType ]::tilstandEgenskaberAttrType[],
ARRAY[tilstandRelTilstandsobjekt]) :: tilstandRegistreringType
;

new_uuid3 := as_create_or_import_tilstand(registrering3);

RETURN NEXT ok(true,'No errors running as_create_or_import_tilstand3');

/*********************************/

expected_search_res_1:=array[new_uuid2]::uuid[];

actual_search_res_1:=as_search_tilstand(null,null,
		ROW(
			null,
			null,-- TilstandStatusTilsType[],
			null,-- TilstandPubliceretTilsType[],
			ARRAY[ ROW (
				'brugervendtnoegle_tilstand_2' --text, 
				,null
				,null
				,null) :: tilstandEgenskaberAttrType ]::tilstandEgenskaberAttrType[],
			null-- TilstandRelationType[]
			)::tilstandRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_1 @> actual_search_res_1 and actual_search_res_1 @>expected_search_res_1 and coalesce(array_length(expected_search_res_1,1),0)=coalesce(array_length(actual_search_res_1,1),0), 'search tilstand #1.');


/*********************************/
expected_search_res_2:=array[new_uuid1,new_uuid2,new_uuid3]::uuid[];

actual_search_res_2:=as_search_tilstand(null,null,
		ROW(
			null,
			null,-- TilstandStatusTilsType[],
			null,-- TilstandPubliceretTilsType[],
			ARRAY[ ROW (
				null --text, 
				,'beskrivelse_tilstand_fælles'
				,null --text, 
				,null) :: tilstandEgenskaberAttrType ]::tilstandEgenskaberAttrType[],
			null-- TilstandRelationType[]
			)::tilstandRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_2 @> actual_search_res_2 and actual_search_res_2 @>expected_search_res_2 and coalesce(array_length(expected_search_res_2,1),0)=coalesce(array_length(actual_search_res_2,1),0), 'search tilstand #2.');
/*********************************/

expected_search_res_3:=array[new_uuid1]::uuid[];

actual_search_res_3:=as_search_tilstand(null,null,
		ROW(
			null,
			null,-- TilstandStatusTilsType[],
			null,-- TilstandPubliceretTilsType[],
			null, -- attr egenskaber
			ARRAY[ROW (
				'tilstandsvaerdi'::tilstandRelationKode,
					virkTilstandsvaerdi1,
				null,
				null,
				null
				,null
				,ROW(null,'82')::TilstandVaerdiRelationAttrType
			) :: tilstandRelationType] ::TilstandRelationType[]
			)::tilstandRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_3 @> actual_search_res_3 and actual_search_res_3 @>expected_search_res_3 and coalesce(array_length(expected_search_res_3,1),0)=coalesce(array_length(actual_search_res_3,1),0), 'search tilstand #3.');
/*********************************/


expected_search_res_4:=array[]::uuid[];

actual_search_res_4:=as_search_tilstand(null,null,
		ROW(
			null,
			null,-- TilstandStatusTilsType[],
			null,-- TilstandPubliceretTilsType[],
			null, -- attr egenskaber
			ARRAY[ROW (
				'tilstandsvaerdi'::tilstandRelationKode,
					virkTilstandsvaerdi1,
				null,
				null,
				null
				,null
				,ROW(false,'82')::TilstandVaerdiRelationAttrType
			) :: tilstandRelationType] ::TilstandRelationType[]
			)::tilstandRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_4 @> actual_search_res_4 and actual_search_res_4 @>expected_search_res_4 and coalesce(array_length(expected_search_res_4,1),0)=coalesce(array_length(actual_search_res_4,1),0), 'search tilstand #4.');
/*********************************/


END;
$$;
