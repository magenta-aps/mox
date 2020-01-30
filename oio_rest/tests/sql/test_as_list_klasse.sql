-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_list_klasse()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid uuid;
	registrering KlasseRegistreringType;
	new_uuid2 uuid;
	registrering2 KlasseRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaber Virkning;
	virkEgenskaberB Virkning;
	virkEgenskaberC Virkning;
	virkEgenskaberD Virkning;
	virkEgenskaberE Virkning;
	virkAnsvarlig Virkning;
	virkRedaktoer1 Virkning;
	virkRedaktoer2 Virkning;
	virkPubliceret Virkning;
	virkPubliceretB Virkning;
	virkPubliceretC Virkning;
	klasseEgenskabA KlasseEgenskaberAttrType;
	klasseEgenskabB KlasseEgenskaberAttrType;
	klasseEgenskabC KlasseEgenskaberAttrType;
	klasseEgenskabD KlasseEgenskaberAttrType;
	klasseEgenskabE KlasseEgenskaberAttrType;
	klassePubliceret KlassePubliceretTilsType;
	klassePubliceretB KlassePubliceretTilsType;
	klassePubliceretC KlassePubliceretTilsType;
	klasseRelAnsvarlig KlasseRelationType;
	klasseRelRedaktoer1 KlasseRelationType;
	klasseRelRedaktoer2 KlasseRelationType;
	uuidAnsvarlig uuid :='be61544e-985f-4559-ac64-7034ae889d53'::uuid;
	uuidRedaktoer1 uuid :='981fe680-3881-4331-a64e-92fc253c687b'::uuid;
	uuidRedaktoer2 uuid :='0b1944e6-4c49-4a24-bf1b-bceef3b6f00f'::uuid;
	uuidRegistrering uuid :='8076ac04-8099-4d0c-ba78-56d0c577023a'::uuid;
	update_reg_id bigint;
	actual_relationer KlasseRelationType[];
	actual_publiceret KlassePubliceretTilsType[];
	actual_egenskaber KlasseEgenskaberAttrType[];
	klasseEgenskabA_Soegeord1 KlasseSoegeordType;
	klasseEgenskabA_Soegeord2 KlasseSoegeordType;
	klasseEgenskabB_Soegeord1 KlasseSoegeordType;
	klasseEgenskabB_Soegeord2 KlasseSoegeordType;
	klasseEgenskabB_Soegeord3 KlasseSoegeordType;
	klasseEgenskabB_Soegeord4 KlasseSoegeordType;
	klasseEgenskabC_Soegeord1 KlasseSoegeordType;
	klasseEgenskabC_Soegeord2 KlasseSoegeordType;
	klasseEgenskabC_Soegeord3 KlasseSoegeordType;
	klasseEgenskabE_Soegeord1 KlasseSoegeordType;
	klasseEgenskabE_Soegeord2 KlasseSoegeordType;
	klasseEgenskabE_Soegeord3 KlasseSoegeordType;
	klasseEgenskabE_Soegeord4 KlasseSoegeordType;
	klasseEgenskabE_Soegeord5 KlasseSoegeordType;
	read_klasse1 KlasseType;
	expected_klasse1 KlasseType;
	read_klasse2 KlasseType;
	expected_klasse2 KlasseType;
	actual_klasses_1 KlasseType[];
	actual_klasses_2 KlasseType[];
	actual_klasses_3 KlasseType[];
	--expected_klasses_1 KlasseType[];
	--expected_klasses_2 KlasseType[];
	expected_klasses_3 KlasseType[];
BEGIN


virkEgenskaber :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          '303514bc-9014-4591-a8a9-22eb37c592f9'::uuid,
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkEgenskaberB :=	ROW (
	'[2014-05-13, 2015-01-01)' :: TSTZRANGE,
          '858a568b-2ad0-4168-8b83-c48b8238106c'::uuid,
          'Bruger',
          'NoteEx7'
          ) :: Virkning
;


virkAnsvarlig :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          '0befe457-cef5-4888-b49c-bbee77e44f99'::uuid,
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkRedaktoer1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          'f700e686-5bed-45b3-9d13-c09bbdf2ad1a'::uuid,
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkRedaktoer2 :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          '1c0ce5a4-02c4-4697-ab39-00b7da0b1f54'::uuid,
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;


virkPubliceret:=	ROW (
	'[2015-05-01, infinity)' :: TSTZRANGE,
          '01cdb20d-1897-4966-9552-0a691f162daf'::uuid,
          'Bruger',
          'NoteEx8'
          ) :: Virkning
;

virkPubliceretB:=	ROW (
	'[2014-05-13, 2015-05-01)' :: TSTZRANGE,
          '38efbe3e-3b93-470a-956a-793ca0c8f219'::uuid,
          'Bruger',
          'NoteEx9'
          ) :: Virkning
;



klasseRelAnsvarlig := ROW (
	'ansvarlig'::KlasseRelationKode,
		virkAnsvarlig,
	uuidAnsvarlig,
	null,
	null
) :: KlasseRelationType
;


klasseRelRedaktoer1 := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer1,
	uuidRedaktoer1,
	null,
	null
) :: KlasseRelationType
;



klasseRelRedaktoer2 := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer2,
	uuidRedaktoer2,
	null,
	null
) :: KlasseRelationType
;


klassePubliceret := ROW (
virkPubliceret,
'Publiceret'
):: KlassePubliceretTilsType
;

klassePubliceretB := ROW (
virkPubliceretB,
'IkkePubliceret'
):: KlassePubliceretTilsType
;


klasseEgenskabA_Soegeord1 := ROW(
'soegeordidentifikator_klasseEgenskabA_Soegeord1',
'beskrivelse_klasseEgenskabA_Soegeord1',
'soegeordskategori_klasseEgenskabA_Soegeord1'
)::KlasseSoegeordType
;
klasseEgenskabA_Soegeord2 := ROW(
'soegeordidentifikator_klasseEgenskabA_Soegeord2',
'beskrivelse_klasseEgenskabA_Soegeord2',
'soegeordskategori_klasseEgenskabA_Soegeord2'
)::KlasseSoegeordType
;

klasseEgenskabA := ROW (
'brugervendt_noegle_A',
   'klassebeskrivelse_A',
   'eksempel_A',
	'omfang_A',
   'titel_A',
   'retskilde_A',
   NULL,--'aendringsnotat_text1',
   'integrationsdata_A',
   ARRAY[klasseEgenskabA_Soegeord1,klasseEgenskabA_Soegeord2]::KlasseSoegeordType[], 
   virkEgenskaber
) :: KlasseEgenskaberAttrType
;


klasseEgenskabB_Soegeord1 := ROW(
'soegeordidentifikator_klasseEgenskabB_Soegeord1',
'beskrivelse_klasseEgenskabB_Soegeord1',
'soegeordskategori_klasseEgenskabB_Soegeord1'
)::KlasseSoegeordType
;
klasseEgenskabB_Soegeord2 := ROW(
'soegeordidentifikator_klasseEgenskabB_Soegeord2',
'beskrivelse_klasseEgenskabB_Soegeord2',
'soegeordskategori_klasseEgenskabB_Soegeord2'
)::KlasseSoegeordType
;

klasseEgenskabB_Soegeord3 := ROW(
'soegeordidentifikator_klasseEgenskabB_Soegeord3',
'beskrivelse_klasseEgenskabB_Soegeord3',
'soegeordskategori_klasseEgenskabB_Soegeord3'
)::KlasseSoegeordType
;
klasseEgenskabB_Soegeord4 := ROW(
'soegeordidentifikator_klasseEgenskabB_Soegeord4',
'beskrivelse_klasseEgenskabB_Soegeord4',
'soegeordskategori_klasseEgenskabB_Soegeord4'
)::KlasseSoegeordType
;


klasseEgenskabE_Soegeord1 := ROW(
'soegeordidentifikator_klasseEgenskabE_Soegeord1',
'beskrivelse_klasseEgenskabE_Soegeord1',
'soegeordskategori_klasseEgenskabE_Soegeord1'
)::KlasseSoegeordType
;
klasseEgenskabE_Soegeord2 := ROW(
'soegeordidentifikator_klasseEgenskabE_Soegeord2',
'beskrivelse_klasseEgenskabE_Soegeord2',
'soegeordskategori_klasseEgenskabE_Soegeord2'
)::KlasseSoegeordType
;

klasseEgenskabE_Soegeord3 := ROW(
'soegeordidentifikator_klasseEgenskabE_Soegeord3',
'beskrivelse_klasseEgenskabE_Soegeord3',
'soegeordskategori_klasseEgenskabE_Soegeord3'
)::KlasseSoegeordType
;
klasseEgenskabE_Soegeord4 := ROW(
'soegeordidentifikator_klasseEgenskabE_Soegeord4',
'beskrivelse_klasseEgenskabE_Soegeord4',
'soegeordskategori_klasseEgenskabE_Soegeord4'
)::KlasseSoegeordType
;

klasseEgenskabE_Soegeord5 := ROW(
'soegeordidentifikator_klasseEgenskabE_Soegeord5',
'beskrivelse_klasseEgenskabE_Soegeord5',
'soegeordskategori_klasseEgenskabE_Soegeord5'
)::KlasseSoegeordType
;


klasseEgenskabB := ROW (
'brugervendt_noegle_B',
   'klassebeskrivelse_B',
   'eksempel_B',
	'omfang_B',
   'titel_B',
   'retskilde_B',
   NULL, --aendringsnotat
   'integrationsdata_B',
    ARRAY[klasseEgenskabB_Soegeord1,klasseEgenskabB_Soegeord2,klasseEgenskabB_Soegeord3,klasseEgenskabB_Soegeord4]::KlasseSoegeordType[], --soegeord
   virkEgenskaberB
) :: KlasseEgenskaberAttrType
;


registrering := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 54') :: RegistreringBase
	,
ARRAY[klassePubliceret,klassePubliceretB]::KlassePubliceretTilsType[],
ARRAY[klasseEgenskabA,klasseEgenskabB]::KlasseEgenskaberAttrType[],
ARRAY[klasseRelRedaktoer2,klasseRelRedaktoer1,klasseRelAnsvarlig]
) :: KlasseRegistreringType
;

new_uuid := as_create_or_import_klasse(registrering);


virkEgenskaberC :=	ROW (
	'[2015-01-13, infinity)' :: TSTZRANGE,
          '668bbef5-be2c-4805-af50-f92195561334'::uuid,
          'Bruger',
          'NoteEx20'
          ) :: Virkning
;

virkEgenskaberD :=	ROW (
	'[2013-06-30, 2014-06-01)' :: TSTZRANGE,
          'fab32a69-2c94-49aa-96fd-cddac42f4ca6'::uuid,
          'Bruger',
          'NoteEx7'
          ) :: Virkning
;

virkEgenskaberE:=	ROW (
	'[2014-08-01, 2014-10-20)' :: TSTZRANGE,
          'bd2c3576-5eeb-42f1-aee1-9460d52a3080'::uuid,
          'Bruger',
          'NoteEx20'
          ) :: Virkning
;

klasseEgenskabC := ROW (
   'brugervendt_noegle_text1',
   NULL, --'klassebeskrivelse_text1',
   NULL,--'eksempel_text1',
	'omfang_C',
   'titel_C',
   'retskilde_C',
   'aendringsnotat_C',
   'integrationsdata_C',
   ARRAY[]::KlasseSoegeordType[], --soegeord
   virkEgenskaberC
) :: KlasseEgenskaberAttrType
;

klasseEgenskabD := ROW (
'brugervendt_noegle_D',
   'klassebeskrivelse_D',
   'eksempel_D',
   'omfang_D',
   'titel_D',
   'retskilde_D',
   NULL, --aendringsnotat
   'integrationsdata_D',
    NULL, --soegeord
   virkEgenskaberD
) :: KlasseEgenskaberAttrType
;

klasseEgenskabE := ROW (
'brugervendt_noegle_E',
   'klassebeskrivelse_E',
   'eksempel_E',
	'omfang_E',
   'titel_E',
   'retskilde_E',
   NULL, --aendringsnotat
   'integrationsdata_E',
    ARRAY[klasseEgenskabE_Soegeord1,klasseEgenskabE_Soegeord2,klasseEgenskabE_Soegeord3,klasseEgenskabE_Soegeord4,klasseEgenskabE_Soegeord5]::KlasseSoegeordType[], --soegeord
   virkEgenskaberE
) :: KlasseEgenskaberAttrType
;

virkPubliceretC:=	ROW (
	'[2015-01-01, 2015-05-01]' :: TSTZRANGE,
          '54506144-5b4d-49b4-8bdf-14258ac28b80'::uuid,
          'Bruger',
          'NoteEx10'
          ) :: Virkning
;



klassePubliceretC := ROW (
virkPubliceretC,
''::KlassePubliceretTils
):: KlassePubliceretTilsType
;


registrering2 := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 5') :: RegistreringBase
	,
array[klassePubliceretC]::KlassePubliceretTilsType[],
  array[klasseEgenskabD,klasseEgenskabE,klasseEgenskabC]::KlasseEgenskaberAttrType[],
  array[klasseRelAnsvarlig]::KlasseRelationType[]
) :: KlasseRegistreringType
;

new_uuid2 := as_create_or_import_klasse(registrering2);

read_Klasse1 := as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);




expected_Klasse1 :=
				ROW(
					new_uuid,
					ARRAY[
						ROW(
							ROW(
								((read_Klasse1.registrering[1]).registrering).timeperiod, --this is cheating, but helps the comparison efforts below. (The timeperiod is set during creation/initialization )
								(registrering.registrering).livscykluskode,
								(registrering.registrering).brugerref,
								(registrering.registrering).note 
								)::RegistreringBase
							,registrering.tilsPubliceret
							,registrering.attrEgenskaber
							,registrering.relationer
						)::KlasseRegistreringType
					]::KlasseRegistreringType[]
			)::KlasseType
;


read_Klasse2 := as_read_Klasse(new_uuid2,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

expected_Klasse2 :=
				ROW(
					new_uuid2,
					ARRAY[
						ROW(
							ROW(
								((read_Klasse2.registrering[1]).registrering).timeperiod, --this is cheating, but helps the comparison efforts below. (The timeperiod is set during creation/initialization )
								(registrering2.registrering).livscykluskode,
								(registrering2.registrering).brugerref,
								(registrering2.registrering).note 
								)::RegistreringBase
							,array[klassePubliceretC]
							,array[
							klasseEgenskabD,klasseEgenskabE,
							ROW(
							klasseEgenskabC.brugervendtnoegle,
							klasseEgenskabC.beskrivelse,
							klasseEgenskabC.eksempel,
							klasseEgenskabC.omfang,
							klasseEgenskabC.titel,
							klasseEgenskabC.retskilde,
							klasseEgenskabC.aendringsnotat,
 							klasseEgenskabC.integrationsdata, 
							NULL, --notice: empty array for soegeord get read as null
 							klasseEgenskabC.virkning 
							)::KlasseEgenskaberAttrType
							]::KlasseEgenskaberAttrType[]
							,registrering2.relationer
						)::KlasseRegistreringType
					]::KlasseRegistreringType[]
			)::KlasseType
;





actual_klasses_1:=as_list_klasse(array[new_uuid]::uuid[],null,null);

--RAISE NOTICE 'actual_klasses_1:%',to_json(actual_klasses_1);
--RAISE NOTICE 'expected_Klasse1_arr_json:%',to_json(ARRAY[expected_Klasse1]);



RETURN NEXT is(
	actual_klasses_1,
	ARRAY[expected_Klasse1],	
	'list klasse test 1');

actual_klasses_2:=as_list_klasse(array[new_uuid2]::uuid[],null,null);


--RAISE NOTICE 'actual_klasses_2:%',to_json(actual_klasses_2);
--RAISE NOTICE 'expected_Klasse2_arr_json:%',to_json(expected_Klasse2);


RETURN NEXT is(
	actual_klasses_2,
	ARRAY[expected_Klasse2],	
	'list klasse test 2');





actual_klasses_3:=as_list_klasse(array[new_uuid,new_uuid2]::uuid[],null,null);


select array_agg(a.* order by a.id) from unnest(ARRAY[expected_Klasse1,expected_Klasse2]) as a into expected_klasses_3;



RETURN NEXT is(
	actual_klasses_3,
	expected_klasses_3,	
	'list klasse test 3');


END;
$$;
