-- SPDX-FileCopyrightText: 2016-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_update_tilstand()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid1 uuid;
	registrering tilstandRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaber Virkning;
	virkEgenskaber2 Virkning;
	virkTilstandsobjekt Virkning;
	virkTilstandsvaerdi1 Virkning;
	virkTilstandsvaerdi1D Virkning;
	virkTilstandsvaerdi2 Virkning;
	virkTilstandskvalitet1 Virkning;
	virkTilstandskvalitet2 Virkning;
	virkPubliceret Virkning;
	virkStatus Virkning;
	virkStatus2 Virkning;
	tilstandEgenskab tilstandEgenskaberAttrType;
	tilstandEgenskab2 tilstandEgenskaberAttrType;
	tilstandStatus tilstandStatusTilsType;
	tilstandStatus2 tilstandStatusTilsType;
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
	uuidVirkEgenskaber uuid :='6f368584-4c3e-4ba4-837b-da2b1eee37ca'::uuid;
	uuidVirkEgenskaber2 uuid :='9f368584-4c3e-4ba4-837b-da2b1eee37cb'::uuid;
	uuidVirkStatus2 uuid:='e470ce13-a546-4940-a1a8-016e4e2197de'::uuid;
	uuidVirkStatus uuid:='cd50aea8-9bef-4914-818c-8f2cfdf42ddf'::uuid;
	actual_publiceret_virk virkning;
	actual_publiceret_value tilstandStatusTils;
	actual_publiceret tilstandStatusTilsType;
	actual_relationer tilstandRelationType[];
	uuid_to_import uuid :='a1819cce-043b-447f-ba5e-92e6a75df918'::uuid;
	uuid_returned_from_import uuid;
	read_Tilstand1 TilstandType;
	read_Tilstand2 TilstandType;
	read_Tilstand3 TilstandType;
	read_Tilstand4 TilstandType;

	expected_tilstand1 TilstandType;
	expected_tilstand2 TilstandType;
	expected_tilstand3 TilstandType;
	expected_tilstand4 TilstandType;

	updated_reg_id_1 bigint;
	updated_reg_id_2 bigint;
	updated_reg_id_3 bigint;
	updated_reg_id_4 bigint;

BEGIN


virkEgenskaber :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          uuidVirkEgenskaber,
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
          uuidVirkStatus,
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
,'beskrivelse_tilstand_1'-- text,
,'integrationsdata_1'-- text,
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

RETURN NEXT ok(true,'No errors running as_create_or_import_tilstand');



/******************************************************************/



virkEgenskaber2 :=	ROW (
	'[2016-05-12, infinity)' :: TSTZRANGE,
          uuidVirkEgenskaber2,
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;

tilstandEgenskab2 := ROW (
'brugervendtnoegle_tilstand_1A' --text, 
,'beskrivelse_tilstand_2'-- text,
,'integrationsdata_2'-- text,
,virkEgenskaber2
) :: tilstandEgenskaberAttrType
;



updated_reg_id_1:=as_update_tilstand(
  new_uuid1,
  uuidRegistrering,
  'Test Note 5',
  'Rettet'::Livscykluskode,           
  ARRAY[tilstandEgenskab2] :: TilstandEgenskaberAttrType[],
  null, --tilsStatus TilstandStatusTilsType[],
  null, -- tilsPubliceret TilstandPubliceretTilsType[],
  null --relationer TilstandRelationType[]
	);


read_Tilstand1 := as_read_tilstand(new_uuid1,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);
--raise notice 'read_Tilstand1:%',to_json(read_Tilstand1);

expected_tilstand1:=ROW(
		new_uuid1,
		ARRAY[
			ROW(
			(read_Tilstand1.registrering[1]).registrering
			,ARRAY[tilstandStatus]::tilstandStatusTilsType[]
			,ARRAY[tilstandPubliceret]::tilstandPubliceretTilsType[]
			,ARRAY[
				 ROW (
				'brugervendtnoegle_tilstand_1' --text, 
				,'beskrivelse_tilstand_1'-- text,
				,'integrationsdata_1'-- text,
				,ROW (
					'[2015-05-12, 2016-05-12)' :: TSTZRANGE,
						uuidVirkEgenskaber,
						'Bruger',
						'NoteEx1'
						) :: Virkning
				),
				  ROW (
					'brugervendtnoegle_tilstand_1A' --text, 
					,'beskrivelse_tilstand_2'-- text,
					,'integrationsdata_2'-- text,
					,virkEgenskaber2
					) :: tilstandEgenskaberAttrType
				]::tilstandEgenskaberAttrType[]
			,ARRAY[
				ROW (
				'tilstandsvaerdi'::tilstandRelationKode,
					virkTilstandsvaerdi2,
				uuidTilstandsvaerdi2,
				null,--urnTilstandsvaerdi2
				'Klasse'
				,2 --NOTICE: Was replace din by import function
				, ROW(null,null)::TilstandVaerdiRelationAttrType --will be removed in python-layer
			) :: tilstandRelationType
			,
				ROW (
				'tilstandskvalitet'::tilstandRelationKode,
					virkTilstandskvalitet2,
				uuidTilstandskvalitet2,
				null,
				'Klasse'
				,2 --NOTICE: Was replaced by import function
				,ROW(null,null)::TilstandVaerdiRelationAttrType --will be removed in python-layer
			) :: tilstandRelationType
			,
				ROW (
				'tilstandskvalitet'::tilstandRelationKode,
					virkTilstandskvalitet1,
				uuidTilstandskvalitet1,
				null,
				'Klasse'
				,1 --NOTICE: Was replaced  by import function
				,ROW(null,null)::TilstandVaerdiRelationAttrType --will be removed in python-layer
			) :: tilstandRelationType
			,
				ROW (
				'tilstandsobjekt'::tilstandRelationKode
				,virkTilstandsobjekt
				,uuidTilstandsobjekt
				,null
				,'Person'
				,NULL --NOTICE: Was replaced
				,ROW(null,null)::TilstandVaerdiRelationAttrType --will be removed in python-layer
			) :: tilstandRelationType
				,
				 ROW (
					'tilstandsvaerdi'::tilstandRelationKode,
						virkTilstandsvaerdi1,
					null,
					null,
					null
					,1 --NOTICE: Was replaced by import function
					,ROW(true,'82')::TilstandVaerdiRelationAttrType
				) :: tilstandRelationType
			
				]::TilstandRelationType[]
			)::TilstandRegistreringType
			]::TilstandRegistreringType[]
		)::TilstandType
;

--raise notice 'expected_tilstand1:%',to_json(expected_tilstand1);

RETURN NEXT IS(
	read_Tilstand1,
	expected_tilstand1
	,'test update tilstand #1'
);


/*****************************************************************/

virkstatus2 := ROW (
	'[2017-01-01, 2017-01-31]' :: TSTZRANGE,
          uuidVirkStatus2,
          'Bruger',
          'NoteEx30'
) :: Virkning
;

tilstandStatus2 := ROW (
virkStatus2,
'Inaktiv'::TilstandStatusTils
):: tilstandStatusTilsType
;



updated_reg_id_2:=as_update_tilstand(
  new_uuid1,
  uuidRegistrering,
  'Test Note 28',
  'Rettet'::Livscykluskode,           
  null, --ARRAY[tilstandEgenskab2] :: TilstandEgenskaberAttrType[],
   array[tilstandStatus2], --tilsStatus TilstandStatusTilsType[],
  null, -- tilsPubliceret TilstandPubliceretTilsType[],
  null --relationer TilstandRelationType[]
	);


read_Tilstand2 := as_read_tilstand(new_uuid1,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

--raise notice 'read_Tilstand2:%',to_json(read_Tilstand2);



expected_tilstand2:=ROW(
		new_uuid1,
		ARRAY[
			ROW(
			(read_Tilstand2.registrering[1]).registrering
			,ARRAY[
				tilstandStatus2,
				ROW (
					ROW(
				'[2016-12-18, 2017-01-01)' :: TSTZRANGE,
				uuidVirkStatus,
				'Bruger',
				'NoteEx20'
				) :: Virkning,
				'Aktiv'::TilstandStatusTils
				):: tilstandStatusTilsType
				,
				ROW (
					ROW(
				'(2017-01-31, infinity)' :: TSTZRANGE,
				uuidVirkStatus,
				'Bruger',
				'NoteEx20'
				) :: Virkning,
				'Aktiv'::TilstandStatusTils
				):: tilstandStatusTilsType
				]::tilstandStatusTilsType[]
			,(expected_tilstand1.registrering[1]).tilsPubliceret
			,(expected_tilstand1.registrering[1]).attrEgenskaber 
			,(expected_tilstand1.registrering[1]).relationer
			)::TilstandRegistreringType
			]::TilstandRegistreringType[]
		)::TilstandType
;

--raise notice 'expected_tilstand2:%',to_json(expected_tilstand2);

RETURN NEXT IS(
	read_Tilstand2,
	expected_tilstand2
	,'test update tilstand #2'
);

/***************************************************/


updated_reg_id_3:=as_update_tilstand(
  new_uuid1,
  uuidRegistrering,
  'Test Note 45',
  'Rettet'::Livscykluskode,           
  null, --ARRAY[tilstandEgenskab2] :: TilstandEgenskaberAttrType[],
  null, --tilsStatus TilstandStatusTilsType[],
  null, -- tilsPubliceret TilstandPubliceretTilsType[],
  ARRAY[ ROW (
					'tilstandsvaerdi'::tilstandRelationKode,
						virkTilstandsvaerdi1,
					null,
					null,
					null
					,1 
					,ROW(true,'85')::TilstandVaerdiRelationAttrType ) ]::TilstandRelationType[]  --relationer TilstandRelationType[]
	);

read_Tilstand3 := as_read_tilstand(new_uuid1,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

--raise notice 'read_Tilstand3:%',to_json(read_Tilstand3);



expected_tilstand3:=ROW(
		new_uuid1,
		ARRAY[
			ROW(
			(read_Tilstand3.registrering[1]).registrering
			,(expected_tilstand2.registrering[1]).tilsStatus
			,(expected_tilstand2.registrering[1]).tilsPubliceret
			,(expected_tilstand2.registrering[1]).attrEgenskaber 
			,ARRAY[
				ROW (
				'tilstandsvaerdi'::tilstandRelationKode,
					virkTilstandsvaerdi2,
				uuidTilstandsvaerdi2,
				null,--urnTilstandsvaerdi2
				'Klasse'
				,2 --NOTICE: Was replace din by import function
				, ROW(null,null)::TilstandVaerdiRelationAttrType --will be removed in python-layer
			) :: tilstandRelationType
			,
				ROW (
				'tilstandskvalitet'::tilstandRelationKode,
					virkTilstandskvalitet2,
				uuidTilstandskvalitet2,
				null,
				'Klasse'
				,2 --NOTICE: Was replaced by import function
				,ROW(null,null)::TilstandVaerdiRelationAttrType --will be removed in python-layer
			) :: tilstandRelationType
			,
				ROW (
				'tilstandskvalitet'::tilstandRelationKode,
					virkTilstandskvalitet1,
				uuidTilstandskvalitet1,
				null,
				'Klasse'
				,1 --NOTICE: Was replaced  by import function
				,ROW(null,null)::TilstandVaerdiRelationAttrType --will be removed in python-layer
			) :: tilstandRelationType
			,
				ROW (
				'tilstandsobjekt'::tilstandRelationKode
				,virkTilstandsobjekt
				,uuidTilstandsobjekt
				,null
				,'Person'
				,NULL --NOTICE: Was replaced
				,ROW(null,null)::TilstandVaerdiRelationAttrType --will be removed in python-layer
			) :: tilstandRelationType
				,
				 ROW (
					'tilstandsvaerdi'::tilstandRelationKode,
						virkTilstandsvaerdi1,
					null,
					null,
					null
					,1 --NOTICE: Was replaced by import function
					,ROW(true,'85')::TilstandVaerdiRelationAttrType
				) :: tilstandRelationType
			
				]::TilstandRelationType[]


			)::TilstandRegistreringType
			]::TilstandRegistreringType[]
		)::TilstandType
;

--raise notice 'expected_tilstand3:%',to_json(expected_tilstand3);

RETURN NEXT IS(
	read_Tilstand3,
	expected_tilstand3
	,'test update tilstand #3'
);

/***********************************************/

virkTilstandsvaerdi1D :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'Værdien blev slettet pga. fejl i indberetning.'
          ) :: Virkning
;

updated_reg_id_4:=as_update_tilstand(
  new_uuid1,
  uuidRegistrering,
  'Test Note 50',
  'Rettet'::Livscykluskode,           
  null, --ARRAY[tilstandEgenskab2] :: TilstandEgenskaberAttrType[],
  null, --tilsStatus TilstandStatusTilsType[],
  null, -- tilsPubliceret TilstandPubliceretTilsType[],
  ARRAY[ ROW (
					'tilstandsvaerdi'::tilstandRelationKode,
						virkTilstandsvaerdi1D,
					null,
					null,
					null
					,1 
					,ROW(null,null)::TilstandVaerdiRelationAttrType ) ]::TilstandRelationType[]  --relationer TilstandRelationType[]
	);

read_Tilstand4 := as_read_tilstand(new_uuid1,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

--raise notice 'read_Tilstand4:%',to_json(read_Tilstand4);

expected_tilstand4:=ROW(
		new_uuid1,
		ARRAY[
			ROW(
			(read_Tilstand4.registrering[1]).registrering
			,(expected_tilstand2.registrering[1]).tilsStatus
			,(expected_tilstand2.registrering[1]).tilsPubliceret
			,(expected_tilstand2.registrering[1]).attrEgenskaber 
			,ARRAY[
				ROW (
				'tilstandsvaerdi'::tilstandRelationKode,
					virkTilstandsvaerdi2,
				uuidTilstandsvaerdi2,
				null,--urnTilstandsvaerdi2
				'Klasse'
				,2 --NOTICE: Was replace din by import function
				, ROW(null,null)::TilstandVaerdiRelationAttrType --will be removed in python-layer
			) :: tilstandRelationType
			,
				ROW (
				'tilstandskvalitet'::tilstandRelationKode,
					virkTilstandskvalitet2,
				uuidTilstandskvalitet2,
				null,
				'Klasse'
				,2 --NOTICE: Was replaced by import function
				,ROW(null,null)::TilstandVaerdiRelationAttrType --will be removed in python-layer
			) :: tilstandRelationType
			,
				ROW (
				'tilstandskvalitet'::tilstandRelationKode,
					virkTilstandskvalitet1,
				uuidTilstandskvalitet1,
				null,
				'Klasse'
				,1 --NOTICE: Was replaced  by import function
				,ROW(null,null)::TilstandVaerdiRelationAttrType --will be removed in python-layer
			) :: tilstandRelationType
			,
				ROW (
				'tilstandsobjekt'::tilstandRelationKode
				,virkTilstandsobjekt
				,uuidTilstandsobjekt
				,null
				,'Person'
				,NULL --NOTICE: Was replaced
				,ROW(null,null)::TilstandVaerdiRelationAttrType --will be removed in python-layer
			) :: tilstandRelationType
				,
				 ROW (
					'tilstandsvaerdi'::tilstandRelationKode,
						virkTilstandsvaerdi1D,
					null,
					null,
					null
					,1 --NOTICE: Was replaced by import function
					,ROW(null,null)::TilstandVaerdiRelationAttrType
				) :: tilstandRelationType
			
				]::TilstandRelationType[]


			)::TilstandRegistreringType
			]::TilstandRegistreringType[]
		)::TilstandType
;

--raise notice 'expected_tilstand4:%',to_json(expected_tilstand4);	

RETURN NEXT IS(
	read_Tilstand4,
	expected_tilstand4
	,'test update tilstand #4'
);

/***********************************************/

END;
$$;
