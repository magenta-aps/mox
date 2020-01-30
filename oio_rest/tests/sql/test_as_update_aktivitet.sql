-- SPDX-FileCopyrightText: 2016-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_update_aktivitet()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid1 uuid;
	registrering aktivitetRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaber Virkning;
	virkEgenskaber2 Virkning;
	virkAnsvarligklasse Virkning;
	virkResultatklasse1 Virkning;
	virkResultatklasse2 Virkning;
	virkDeltagerklasse1 Virkning;
	virkDeltagerklasse2 Virkning;
	virkUdfoerer1 Virkning;
	virkUdfoerer2 Virkning;
	virkUdfoerer2B Virkning;
	virkUdfoerer3 Virkning;
	virkGeoobjekt Virkning;
	virkPubliceret Virkning;
	virkStatus Virkning;
	virkStatus1B Virkning;
	aktivitetEgenskab aktivitetEgenskaberAttrType;
	aktivitetEgenskab2 aktivitetEgenskaberAttrType;
	aktivitetEgenskab2B aktivitetEgenskaberAttrType;
	aktivitetStatus aktivitetStatusTilsType;
	aktivitetStatus1B aktivitetStatusTilsType;
	aktivitetPubliceret aktivitetPubliceretTilsType;
	aktivitetRelAnsvarligklasse aktivitetRelationType;
	aktivitetRelResultatklasse1 aktivitetRelationType;
	aktivitetRelResultatklasse2 aktivitetRelationType;
	aktivitetRelDeltagerklasse1 aktivitetRelationType;
	aktivitetRelDeltagerklasse2 aktivitetRelationType;
	aktivitetRelUdfoerer1 aktivitetRelationType;
	aktivitetRelUdfoerer2 aktivitetRelationType;
	aktivitetRelUdfoerer2B aktivitetRelationType;
	aktivitetRelUdfoerer3 aktivitetRelationType;
	aktivitetRelGeoobjekt aktivitetRelationType;
	uuidAnsvarligklasse uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	uuidResultatklasse1 uuid :='b7160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;
	uuidVirkStatusAktoerRef uuid :='995e00fa-8675-479d-a0e0-272a85047954'::uuid;

	--uuidResultatklasse2 uuid :='08533179-fedb-4aa7-8902-ab34a219eed9'::uuid;
	urnResultatklasse2 text:='urn:isbn:0451450523'::text;
	uuidDeltagerklasse1 uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09d'::uuid;
	uuidDeltagerklasse2 uuid :='28533179-fedb-4aa7-8902-ab34a219eed1'::uuid;
	uuidUdfoerer1  uuid :='884d99f6-568f-4772-8766-fac6d40f9cb0'::uuid;
	uuidUdfoerer2  uuid :='b6bb8e41-b47b-4420-b2a3-d1c38d86a1ad'::uuid;
	uuidUdfoerer3  uuid :='30323d2f-3b3d-41ff-81dc-bbbc1d77d4f9'::uuid;
	uuidGeoobjekt  uuid :='17da4471-fdf4-4b92-ba71-be60eaa6aa42'::uuid;
	uuidRegistrering uuid :='1f368584-4c3e-4ba4-837b-da2b1eee37c9'::uuid;
	repraesentation_uuid uuid :='0e3ed41a-08f2-4967-8689-dce625f93029'::uuid;
	repraesentation_urn text :='isbn:97800232324'::text;
	repraesentation_urn2 text :='isbn:97800800045'::text;
	actual_publiceret_virk virkning;
	actual_publiceret_value aktivitetStatusTils;
	actual_publiceret aktivitetStatusTilsType;
	actual_relationer aktivitetRelationType[];
	uuid_to_import uuid :='a1819cce-043b-447f-ba5e-92e6a75df918'::uuid;
	uuid_returned_from_import uuid;
	update_reg_id_1 int;
	update_reg_id_2 int;
	read_Aktivitet1 AktivitetType;
	expected_aktivitet1 AktivitetType;
BEGIN


virkEgenskaber :=	ROW (
	'[2015-05-12, 2015-06-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkEgenskaber2 :=	ROW (
	'[2015-06-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx90'
          ) :: Virkning
;

virkAnsvarligklasse :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkUdfoerer1 :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx342'
          ) :: Virkning
;

virkUdfoerer2 :=	ROW (
	'[2016-04-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx350'
          ) :: Virkning
;



virkResultatklasse1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkResultatklasse2 :=	ROW (
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
          uuidVirkStatusAktoerRef,
          'Bruger',
          'NoteEx20'
) :: Virkning
;

virkDeltagerklasse1 :=	ROW (
	'[2015-04-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx23'
          ) :: Virkning
;


virkDeltagerklasse2 :=	ROW (
	'[2015-06-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx12'
          ) :: Virkning
;

aktivitetRelAnsvarligklasse := ROW (
	'ansvarligklasse'::aktivitetRelationKode
	,virkAnsvarligklasse
	,uuidAnsvarligklasse
	,null
	,'Klasse'
	,567 --NOTICE: Should be replace in by import function
	,null --aktoerAttr
) :: aktivitetRelationType
;

aktivitetRelUdfoerer1 := ROW (
	'udfoerer'::aktivitetRelationKode
	,virkUdfoerer1
	,uuidUdfoerer1
	,null
	,'Person'
	,3 --NOTICE: Should be replace in by import function
	,ROW (
		 'valgfri'::AktivitetAktoerAttrObligatoriskKode,
  		'foreloebigt'::AktivitetAktoerAttrAccepteretKode,
  repraesentation_uuid,
  null 
	)::AktivitetAktoerAttr
) :: aktivitetRelationType
;


aktivitetRelUdfoerer2 := ROW (
	'udfoerer'::aktivitetRelationKode
	,virkUdfoerer2
	,uuidUdfoerer2
	,null
	,'Person'
	,3 --NOTICE: Should be replace in by import function
	,ROW (
		 'noedvendig'::AktivitetAktoerAttrObligatoriskKode,
  		'accepteret'::AktivitetAktoerAttrAccepteretKode,
  null,
  repraesentation_urn
	)::AktivitetAktoerAttr
) :: aktivitetRelationType
;


aktivitetRelResultatklasse1 := ROW (
	'resultatklasse'::aktivitetRelationKode,
		virkResultatklasse1,
	uuidResultatklasse1,
	null,
	'Klasse'
	,768 --NOTICE: Should be replace in by import function
	,null --aktoerAttr
) :: aktivitetRelationType
;



aktivitetRelResultatklasse2 := ROW (
	'resultatklasse'::aktivitetRelationKode,
		virkResultatklasse2,
	null,
	urnResultatklasse2,
	'Klasse'
	,800 --NOTICE: Should be replace in by import function
	,null --aktoerAttr
) :: aktivitetRelationType
;



aktivitetRelDeltagerklasse1 := ROW (
	'deltagerklasse'::aktivitetRelationKode,
		virkDeltagerklasse1,
	uuidDeltagerklasse1,
	null,
	'Klasse'
	,7268 --NOTICE: Should be replace in by import function
	,null --aktoerAttr
) :: aktivitetRelationType
;



aktivitetRelDeltagerklasse2 := ROW (
	'deltagerklasse'::aktivitetRelationKode,
		virkDeltagerklasse2,
	uuidDeltagerklasse2,
	null,
	'Klasse'
	,3 --NOTICE: Should be replace in by import function
	,null --aktoerAttr
) :: aktivitetRelationType
;



aktivitetStatus := ROW (
virkStatus,
'Aktiv'::AktivitetStatusTils
):: aktivitetStatusTilsType
;

aktivitetPubliceret := ROW (
virkPubliceret,
'Normal'::AktivitetPubliceretTils
)::aktivitetPubliceretTilsType;


aktivitetEgenskab := ROW (
 'aktivitet_1_brugervendtnoegle',
 'aktivitet_1_aktivitetnavn',
 'aktivitet_1_beskrivelse',
 '2017-02-25 17:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
'2017-02-27 08:00'::timestamptz, -- sluttidspunkt,
  INTERVAL '0000-00 03 02:30:00.0', --tidsforbrug
 'aktivitet_1_formaal',
 'integrationsdata_1'
,virkEgenskaber
) :: aktivitetEgenskaberAttrType
;

aktivitetEgenskab2 := ROW (
 'aktivitet_2_brugervendtnoegle',
 'aktivitet_2_aktivitetnavn',
 'aktivitet_2_beskrivelse',
 '2016-04-20 10:00'::timestamptz,  --'starttidspunkt_aktivitet_1' --text
'2017-02-27 12:00'::timestamptz, -- sluttidspunkt,
  INTERVAL '0000-00 01 04:00:01.0', --tidsforbrug
 'aktivitet_2_formaal',
 'integrationsdata_2'
,virkEgenskaber2
) :: aktivitetEgenskaberAttrType
;


registrering := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
	ARRAY[aktivitetStatus]::aktivitetStatusTilsType[],
	ARRAY[aktivitetPubliceret]::AktivitetPubliceretTilsType[],
ARRAY[aktivitetEgenskab,aktivitetEgenskab2]::aktivitetEgenskaberAttrType[],
ARRAY[aktivitetRelAnsvarligklasse,aktivitetRelResultatklasse1,aktivitetRelResultatklasse2,aktivitetRelDeltagerklasse1,aktivitetRelDeltagerklasse2,aktivitetRelUdfoerer1,aktivitetRelUdfoerer2]) :: aktivitetRegistreringType
;


--raise notice 'to be written aktivitet 1:%',to_json(registrering);

new_uuid1 := as_create_or_import_aktivitet(registrering);


/*************************************************************************************************************/

virkUdfoerer2B :=	ROW (
	'[2016-05-20, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx350'
          ) :: Virkning
;

aktivitetRelUdfoerer2B := ROW (
	'udfoerer'::aktivitetRelationKode
	,virkUdfoerer2B
	,uuidUdfoerer2
	,null
	,'Person'
	,2 
	,ROW (
		 'valgfri'::AktivitetAktoerAttrObligatoriskKode,
  		'foreloebigt'::AktivitetAktoerAttrAccepteretKode,
  null,
  repraesentation_urn
	)::AktivitetAktoerAttr
) :: aktivitetRelationType
;


virkUdfoerer3 :=	ROW (
	'[2017-10-30, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx7800'
          ) :: Virkning
;

aktivitetRelUdfoerer3 := ROW (
	'udfoerer'::aktivitetRelationKode
	,virkUdfoerer3
	,uuidUdfoerer3
	,null
	,'Person'
	,null
	,ROW (
		 'noedvendig'::AktivitetAktoerAttrObligatoriskKode,
  		'afslaaet'::AktivitetAktoerAttrAccepteretKode,
  null,
  repraesentation_urn2
	)::AktivitetAktoerAttr
) :: aktivitetRelationType
;


virkGeoobjekt :=ROW (
	'[2016-03-25, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx7001'
          ) :: Virkning
;

aktivitetRelGeoobjekt:= ROW (
	'geoobjekt'::aktivitetRelationKode
	,virkGeoobjekt
	,uuidGeoobjekt
	,null
	,'Geoobjekt'
	,null
	,ROW (
		 'valgfri'::AktivitetAktoerAttrObligatoriskKode,
  		'foreloebigt'::AktivitetAktoerAttrAccepteretKode,
  null,
  repraesentation_urn
	)::AktivitetAktoerAttr --Notice: Should be discarded for relations of the 'wrong' types like this type
) :: aktivitetRelationType
;


virkStatus1B := ROW (
	'[2017-05-20, 2017-07-30]' :: TSTZRANGE,
          uuidVirkStatusAktoerRef,
          'Bruger',
          'NoteEx500'
) :: Virkning
;

aktivitetStatus1B := ROW (
virkStatus1B,
'Inaktiv'::AktivitetStatusTils
):: aktivitetStatusTilsType
;


aktivitetEgenskab2B := ROW (
 null, --'aktivitet_2_brugervendtnoegle',
 null, --'aktivitet_2_aktivitetnavn',
 null,--'aktivitet_2_beskrivelse',
 ''::text,  --'starttidspunkt_aktivitet_1' --text
null, --'2017-02-27 12:00'::timestamptz, -- sluttidspunkt,
 ''::text,-- INTERVAL '0000-00 01 04:00:01.0', --tidsforbrug
 null,--'aktivitet_2_formaal'
 null--'integrationsdata_2'
,virkEgenskaber2
) :: aktivitetEgenskaberAttrType
;


update_reg_id_1:=as_update_aktivitet(
  new_uuid1, '5f368584-4c3e-4ba4-837b-da2b1eee37c4'::uuid,'Test update 20'::text,
  'Rettet'::Livscykluskode,          
  array[aktivitetEgenskab2B]::aktivitetEgenskaberAttrType[],
   array[aktivitetStatus1B]::aktivitetStatusTilsType[],
 null,
  array[aktivitetRelUdfoerer2B,aktivitetRelUdfoerer3,aktivitetRelGeoobjekt]::AktivitetRelationType[]
	);



read_Aktivitet1 := as_read_aktivitet(new_uuid1,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

--raise notice 'read_updated_Aktivitet1:%',to_json(read_Aktivitet1);


expected_aktivitet1:=ROW(
		new_uuid1,
		ARRAY[
			ROW(
			(read_Aktivitet1.registrering[1]).registrering
			,ARRAY[
				aktivitetStatus1B
				,ROW (
							ROW (
				'[2016-12-18, 2017-05-20)' :: TSTZRANGE,
					uuidVirkStatusAktoerRef,
					'Bruger',
					'NoteEx20'
			) :: Virkning,
				'Aktiv'::AktivitetStatusTils
				):: aktivitetStatusTilsType
			,	
			ROW (
							ROW (
				'(2017-07-30, infinity)' :: TSTZRANGE,
					uuidVirkStatusAktoerRef,
					'Bruger',
					'NoteEx20'
			) :: Virkning,
				'Aktiv'::AktivitetStatusTils
				):: aktivitetStatusTilsType
			]::aktivitetStatusTilsType[]
			,ARRAY[aktivitetPubliceret]::aktivitetPubliceretTilsType[]
			,ARRAY[aktivitetEgenskab,
							ROW (
				'aktivitet_2_brugervendtnoegle',
				'aktivitet_2_aktivitetnavn',
				'aktivitet_2_beskrivelse',
				Row(null,null)::ClearableTimestamptz,  --was cleared
				'2017-02-27 12:00'::timestamptz, -- sluttidspunkt,
				Row(null,null)::ClearableInterval, --was cleared
				'aktivitet_2_formaal',
				'integrationsdata_2'
				,virkEgenskaber2
				) :: aktivitetEgenskaberAttrType
			]::aktivitetEgenskaberAttrType[]
			,ARRAY[
					ROW ( --Notice: Was added
						'geoobjekt'::aktivitetRelationKode
						,virkGeoobjekt
						,uuidGeoobjekt
						,null
						,'Geoobjekt'
						,1
						,ROW (null,null,null,null)::AktivitetAktoerAttr --Notice: Should be discarded for relations of the 'wrong' types like this type
					) :: aktivitetRelationType
					,
				ROW (
				'deltagerklasse'::aktivitetRelationKode,
					virkDeltagerklasse2,
				uuidDeltagerklasse2,
				null,
				'Klasse'
				,2 --NOTICE: Should be replace in by import function
				,ROW (null,null,null,null)::AktivitetAktoerAttr   --NOTICE: empty composites will be removed in python layer --aktoerAttr
			) :: aktivitetRelationType
			,
							ROW (
					'udfoerer'::aktivitetRelationKode
					,virkUdfoerer3
					,uuidUdfoerer3
					,null
					,'Person'
					,3
					,ROW (
						'noedvendig'::AktivitetAktoerAttrObligatoriskKode,
						'afslaaet'::AktivitetAktoerAttrAccepteretKode,
				null,
				repraesentation_urn2
					)::AktivitetAktoerAttr
				) :: aktivitetRelationType
			,	
			ROW (
					'udfoerer'::aktivitetRelationKode
					,virkUdfoerer1
					,uuidUdfoerer1
					,null
					,'Person'
					,1 --NOTICE: was replaced by import function
					,ROW (
						'valgfri'::AktivitetAktoerAttrObligatoriskKode,
						'foreloebigt'::AktivitetAktoerAttrAccepteretKode,
				repraesentation_uuid,
				null 
					)::AktivitetAktoerAttr
				) :: aktivitetRelationType
				,
				ROW ( --NOTICE: Was updated
					'udfoerer'::aktivitetRelationKode
					,virkUdfoerer2B
					,uuidUdfoerer2
					,null
					,'Person'
					,2 
					,ROW (
						'valgfri'::AktivitetAktoerAttrObligatoriskKode,
						'foreloebigt'::AktivitetAktoerAttrAccepteretKode,
				null,
				repraesentation_urn
					)::AktivitetAktoerAttr
				) :: aktivitetRelationType
				,
				ROW (
					'resultatklasse'::aktivitetRelationKode,
						virkResultatklasse1,
					uuidResultatklasse1,
					null,
					'Klasse'
					,1 --NOTICE: Was replaced
					,ROW (null,null,null,null)::AktivitetAktoerAttr  --aktoerAttr
				) :: aktivitetRelationType
				,
				ROW (
				'deltagerklasse'::aktivitetRelationKode,
					virkDeltagerklasse1,
				uuidDeltagerklasse1,
				null,
				'Klasse'
				,1 --NOTICE: Was replaced  by import function
				,ROW (null,null,null,null)::AktivitetAktoerAttr  --aktoerAttr
			) :: aktivitetRelationType,

				ROW (
				'ansvarligklasse'::aktivitetRelationKode
				,virkAnsvarligklasse
				,uuidAnsvarligklasse
				,null
				,'Klasse'
				,NULL --NOTICE: Was replaced
				,ROW (null,null,null,null)::AktivitetAktoerAttr  --aktoerAttr
			) :: aktivitetRelationType
			,ROW (
				'resultatklasse'::aktivitetRelationKode,
					virkResultatklasse2,
				null,
				urnResultatklasse2,
				'Klasse'
				,2 --NOTICE: Was replaced
				,ROW (null,null,null,null)::AktivitetAktoerAttr  --aktoerAttr
			) :: aktivitetRelationType

				]::AktivitetRelationType[]
			)::AktivitetRegistreringType
			]::AktivitetRegistreringType[]
		)::AktivitetType
;

--raise notice 'expected_updated_aktivitet1:%',to_json(expected_aktivitet1);



RETURN NEXT IS(
	read_Aktivitet1,
	expected_aktivitet1
	,'test update aktivitet #1'
);


--TODO: Test: To delete / clear a relation with a given index, you specify a blank uuid and/or a blank urn for that particular index.

/******************************************************/

--Test if providing empty arguments will trigger exception as expected 
BEGIN

update_reg_id_2:=as_update_aktivitet(
  new_uuid1, '5f368584-4c3e-4ba4-837b-da2b1eee37c4'::uuid,'Test update 20'::text,
  'Rettet'::Livscykluskode,          
  null,
  null,
  null,
  null
	);

RETURN NEXT ok(false,'as_update_aktivitet empty arguments: Should throw MO400 exception');
EXCEPTION  
WHEN sqlstate 'MO400' THEN
	RETURN NEXT ok(true,'as_update_aktivitet empty arguments: Throws MO400 exception (as it should)');

END;







END;
$$;
