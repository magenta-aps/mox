-- SPDX-FileCopyrightText: 2016-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_update_indsats()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid1 uuid;
	registrering indsatsRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaber Virkning;
	virkEgenskaber1B Virkning;
	virkIndsatsmodtager Virkning;
	virkIndsatsmodtager1B Virkning;
	virkIndsatssag1 Virkning;
	virkIndsatssag2 Virkning;
	virkIndsatsaktoer1 Virkning;
	virkIndsatsaktoer2 Virkning;
	virkIndsatsaktoer2B Virkning;
	virkPubliceret Virkning;
	virkFremdrift Virkning;
	indsatsEgenskab indsatsEgenskaberAttrType;
	indsatsEgenskab1B indsatsEgenskaberAttrType;
	indsatsFremdrift indsatsFremdriftTilsType;
	indsatsPubliceret indsatsPubliceretTilsType;
	indsatsRelIndsatsmodtager indsatsRelationType;
	indsatsRelIndsatsmodtager1B indsatsRelationType;
	indsatsRelIndsatssag1 indsatsRelationType;
	indsatsRelIndsatssag2 indsatsRelationType;
	indsatsRelIndsatsaktoer1 indsatsRelationType;
	indsatsRelIndsatsaktoer2 indsatsRelationType;
	indsatsRelIndsatsaktoer2B indsatsRelationType;

	uuidIndsatsmodtager uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	uuidIndsatssag1 uuid :='b7160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;
	uuidIndsatsmodtager1B uuid:='7ce114e4-4378-4b73-95ff-fb9a5b651e70'::uuid;
	uuidVirkIndsatsmodtager uuid:='88a7a37b-5423-4a4f-af64-b2031d0aa6a4'::uuid;
	uuidVirkIndsatsmodtager1B uuid:='36171c3f-0018-4b89-accb-f0b89a41acea'::uuid;
	
	--uuidIndsatssag2 uuid :='08533179-fedb-4aa7-8902-ab34a219eed9'::uuid;
	urnIndsatssag2 text:='urn:isbn:0451450523'::text;
	uuidIndsatsaktoer1 uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09d'::uuid;
	uuidIndsatsaktoer2 uuid :='28533179-fedb-4aa7-8902-ab34a219eed1'::uuid;
	uuidIndsatsaktoer2B uuid :='a9642e50-4a8e-4fda-980a-38a0a87e25a9'::uuid;
	uuidRegistrering uuid :='1f368584-4c3e-4ba4-837b-da2b1eee37c9'::uuid;
	uuidVirkEgenskaber uuid :='08a9a73a-184d-4f35-8ab4-51eeb118881f'::uuid;
	uuidVirkEgenskaber1B uuid :='cbb7c86b-a915-44db-ad34-2de9f7f2aad5'::uuid;
	actual_publiceret_virk virkning;
	actual_publiceret_value indsatsFremdriftTils;
	actual_publiceret indsatsFremdriftTilsType;
	actual_relationer indsatsRelationType[];
	uuid_to_import uuid :='a1819cce-043b-447f-ba5e-92e6a75df918'::uuid;
	uuid_returned_from_import uuid;
	read_Indsats1 IndsatsType;
	read_Indsats2 IndsatsType;
	expected_indsats1 IndsatsType;
	expected_indsats2 IndsatsType;

	updated_indstats_regid_1 bigint;
	updated_indstats_regid_2 bigint;
BEGIN


virkEgenskaber :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          uuidVirkEgenskaber,
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkIndsatsmodtager :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          uuidVirkIndsatsmodtager,
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkIndsatssag1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkIndsatssag2 :=	ROW (
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

virkfremdrift := ROW (
	'[2016-12-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx20'
) :: Virkning
;

virkIndsatsaktoer1 :=	ROW (
	'[2015-04-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx23'
          ) :: Virkning
;


virkIndsatsaktoer2 :=	ROW (
	'[2015-06-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx12'
          ) :: Virkning
;

indsatsRelIndsatsmodtager := ROW (
	'indsatsmodtager'::indsatsRelationKode
	,virkIndsatsmodtager
	,uuidIndsatsmodtager
	,null
	,'Person'
	,567 --NOTICE: Should be replace in by import function
) :: indsatsRelationType
;


indsatsRelIndsatssag1 := ROW (
	'indsatssag'::indsatsRelationKode,
		virkIndsatssag1,
	uuidIndsatssag1,
	null,
	'Sag'
	,768 --NOTICE: Should be replace in by import function
) :: indsatsRelationType
;



indsatsRelIndsatssag2 := ROW (
	'indsatssag'::indsatsRelationKode,
		virkIndsatssag2,
	null,
	urnIndsatssag2,
	'Sag'
	,800 --NOTICE: Should be replace in by import function
) :: indsatsRelationType
;



indsatsRelIndsatsaktoer1 := ROW (
	'indsatsaktoer'::indsatsRelationKode,
		virkIndsatsaktoer1,
	uuidIndsatsaktoer1,
	null,
	'Person'
	,7268 --NOTICE: Should be replace in by import function
) :: indsatsRelationType
;



indsatsRelIndsatsaktoer2 := ROW (
	'indsatsaktoer'::indsatsRelationKode,
		virkIndsatsaktoer2,
	uuidIndsatsaktoer2,
	null,
	'Person'
	,3 --NOTICE: Should be replace in by import function
) :: indsatsRelationType
;



indsatsFremdrift := ROW (
virkFremdrift,
'Visiteret'::IndsatsFremdriftTils
):: indsatsFremdriftTilsType
;

indsatsPubliceret := ROW (
virkPubliceret,
'Normal'::IndsatsPubliceretTils
)::indsatsPubliceretTilsType;

indsatsEgenskab := ROW (
'brugervendtnoegle_indsats_1' --text, 
,'beskrivelse_indsats_1'-- text,
, '2017-01-20 08:00'::timestamptz  -- starttidspunkt,
, '2017-01-20 12:00'::timestamptz -- sluttidspunkt,
,'integrationsdata_1'-- text,
,virkEgenskaber
) :: indsatsEgenskaberAttrType
;


registrering := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
	ARRAY[indsatsPubliceret]::IndsatsPubliceretTilsType[],
ARRAY[indsatsFremdrift]::indsatsFremdriftTilsType[],
ARRAY[indsatsEgenskab]::indsatsEgenskaberAttrType[],
ARRAY[indsatsRelIndsatsmodtager,indsatsRelIndsatssag1,indsatsRelIndsatssag2,indsatsRelIndsatsaktoer1,indsatsRelIndsatsaktoer2]) :: indsatsRegistreringType
;


--raise notice 'to be written indsats 1:%',to_json(registrering);

new_uuid1 := as_create_or_import_indsats(registrering);

RETURN NEXT ok(true,'No errors running as_create_or_import_indsats');




/***************************************************************/


virkEgenskaber1B :=	ROW (
	'[2017-01-01, 2017-12-31]' :: TSTZRANGE,
          uuidVirkEgenskaber1B,
          'Bruger',
          'NoteEx32'
          ) :: Virkning
;

indsatsEgenskab1B:= ROW (
null --text, 
,'beskrivelse_indsats_1A'-- text,
, ''::text
, '2017-01-20 13:00'::timestamptz -- sluttidspunkt,
,'integrationsdata_1A'-- text,
,virkEgenskaber1B
) :: indsatsEgenskaberAttrType
;

 updated_indstats_regid_1:=as_update_indsats(
  new_uuid1,
  uuidRegistrering,
  'Opdatering reg note test #1',
  'Rettet'::Livscykluskode,           
  ARRAY[indsatsEgenskab1B]::IndsatsEgenskaberAttrType[],
  null,
  null,
  null
 );

read_Indsats1 := as_read_indsats(new_uuid1,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

--raise notice 'read_Indsats1:%',to_json(read_Indsats1);


expected_indsats1:=ROW(
		new_uuid1,
		ARRAY[
			ROW(
			(read_Indsats1.registrering[1]).registrering
			,ARRAY[indsatsPubliceret]::indsatsPubliceretTilsType[]
			,ARRAY[indsatsFremdrift]::indsatsFremdriftTilsType[]
			,ARRAY[
				ROW (
						'brugervendtnoegle_indsats_1' --text, 
						,'beskrivelse_indsats_1'-- text,
						, '2017-01-20 08:00'::timestamptz  -- starttidspunkt,
						, '2017-01-20 12:00'::timestamptz -- sluttidspunkt,
						,'integrationsdata_1'-- text,
						,ROW (
							'[2015-05-12, 2017-01-01)' :: TSTZRANGE,
								uuidVirkEgenskaber,
								'Bruger',
								'NoteEx1'
								) :: Virkning
						) :: indsatsEgenskaberAttrType,
				ROW (
						'brugervendtnoegle_indsats_1' --text, 
						,'beskrivelse_indsats_1'-- text,
						, '2017-01-20 08:00'::timestamptz  -- starttidspunkt,
						, '2017-01-20 12:00'::timestamptz -- sluttidspunkt,
						,'integrationsdata_1'-- text,
						,ROW (
							'(2017-12-31, infinity)' :: TSTZRANGE,
								uuidVirkEgenskaber,
								'Bruger',
								'NoteEx1'
								) :: Virkning
						) :: indsatsEgenskaberAttrType,
				ROW (
						'brugervendtnoegle_indsats_1' --text, 
						,'beskrivelse_indsats_1A'-- text,
						, row(null,null)
						, '2017-01-20 13:00'::timestamptz -- sluttidspunkt,
						,'integrationsdata_1A'-- text,
						,virkEgenskaber1B
						) :: indsatsEgenskaberAttrType
						
			]::indsatsEgenskaberAttrType[]
			,ARRAY[
				ROW (
				'indsatsaktoer'::indsatsRelationKode,
					virkIndsatsaktoer2,
				uuidIndsatsaktoer2,
				null,
				'Person'
				,2 
			) :: indsatsRelationType
				,
				ROW (
					'indsatssag'::indsatsRelationKode,
						virkIndsatssag1,
					uuidIndsatssag1,
					null,
					'Sag'
					,1 --NOTICE: Was replaced
				) :: indsatsRelationType
				,
				ROW (
				'indsatsaktoer'::indsatsRelationKode,
					virkIndsatsaktoer1,
				uuidIndsatsaktoer1,
				null,
				'Person'
				,1 --NOTICE: Was replaced  by import function
			) :: indsatsRelationType
			,
				ROW (
				'indsatsmodtager'::indsatsRelationKode
				,virkIndsatsmodtager
				,uuidIndsatsmodtager
				,null
				,'Person'
				,NULL --NOTICE: Was replaced
			) :: indsatsRelationType
			,ROW (
				'indsatssag'::indsatsRelationKode,
					virkIndsatssag2,
				null,
				urnIndsatssag2,
				'Sag'
				,2 --NOTICE: Was replaced
			) :: indsatsRelationType

				]::IndsatsRelationType[]
			)::IndsatsRegistreringType
			]::IndsatsRegistreringType[]
		)::IndsatsType
;

--raise notice 'expected_indsats1:%',to_json(expected_indsats1);


RETURN NEXT IS(
	read_Indsats1,
	expected_indsats1
	,'test update indsats #1'
);

/*****************************************/


virkIndsatsmodtager1B :=	ROW (
	'[2017-01-01, 2017-12-31]' :: TSTZRANGE,
          uuidVirkIndsatsmodtager1B,
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

indsatsRelIndsatsmodtager1B := ROW (
	'indsatsmodtager'::indsatsRelationKode
	,virkIndsatsmodtager1B
	,uuidIndsatsmodtager1B
	,null
	,'Person'
	,600 --NOTICE: Should be replace in by import function
) :: indsatsRelationType
;

virkIndsatsaktoer2B :=	ROW (
	'[2016-03-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx12'
          ) :: Virkning
;

indsatsRelIndsatsaktoer2B := ROW (
				'indsatsaktoer'::indsatsRelationKode,
					virkIndsatsaktoer2B,
				uuidIndsatsaktoer2B,
				null,
				'Person'
				,2 
			) :: indsatsRelationType
;


 updated_indstats_regid_2:=as_update_indsats(
  new_uuid1,
  uuidRegistrering,
  'Opdatering reg note test #2',
  'Rettet'::Livscykluskode,           
  null,
  null,
  null,
  ARRAY[indsatsRelIndsatsmodtager1B,indsatsRelIndsatsaktoer2B]
 );


read_Indsats2 := as_read_indsats(new_uuid1,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

--raise notice 'read_Indsats2:%',to_json(read_Indsats2);


expected_indsats2:=ROW(
		new_uuid1,
		ARRAY[
			ROW(
			(read_Indsats2.registrering[1]).registrering
			,(expected_indsats1.registrering[1]).tilsPubliceret
			,(expected_indsats1.registrering[1]).tilsFremdrift
			,(expected_indsats1.registrering[1]).attrEgenskaber
			,ARRAY[
				ROW (
					'indsatsmodtager'::indsatsRelationKode
					,virkIndsatsmodtager1B
					,uuidIndsatsmodtager1B
					,null
					,'Person'
					,null --NOTICE: Should be replace in by import function
				) :: indsatsRelationType,
				ROW (
				'indsatsaktoer'::indsatsRelationKode,
					virkIndsatsaktoer2B,
				uuidIndsatsaktoer2B,
				null,
				'Person'
				,2 
			) :: indsatsRelationType
				,
				ROW (
					'indsatssag'::indsatsRelationKode,
						virkIndsatssag1,
					uuidIndsatssag1,
					null,
					'Sag'
					,1 --NOTICE: Was replaced
				) :: indsatsRelationType
				,
				ROW (
				'indsatsaktoer'::indsatsRelationKode,
					virkIndsatsaktoer1,
				uuidIndsatsaktoer1,
				null,
				'Person'
				,1 --NOTICE: Was replaced  by import function
			) :: indsatsRelationType
			,
			 
				ROW (
				'indsatsmodtager'::indsatsRelationKode
				,ROW (
					'[2015-05-11, 2017-01-01)' :: TSTZRANGE,
						uuidVirkIndsatsmodtager,
						'Bruger',
						'NoteEx2'
						) :: Virkning
				,uuidIndsatsmodtager
				,null
				,'Person'
				,NULL 
			) :: indsatsRelationType
				,
				ROW (
				'indsatsmodtager'::indsatsRelationKode
				,ROW (
					'(2017-12-31, infinity)' :: TSTZRANGE,
						uuidVirkIndsatsmodtager,
						'Bruger',
						'NoteEx2'
						) :: Virkning
				,uuidIndsatsmodtager
				,null
				,'Person'
				,NULL 
			) :: indsatsRelationType

			,ROW (
				'indsatssag'::indsatsRelationKode,
					virkIndsatssag2,
				null,
				urnIndsatssag2,
				'Sag'
				,2 --NOTICE: Was replaced
			) :: indsatsRelationType

				]::IndsatsRelationType[]
			)::IndsatsRegistreringType
			]::IndsatsRegistreringType[]
		)::IndsatsType
;


--raise notice 'expected_indsats2:%',to_json(expected_indsats2);


RETURN NEXT IS(
	read_Indsats2,
	expected_indsats2
	,'test update indsats #2'
);


END;
$$;
