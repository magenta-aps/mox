-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_read_klasse()
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
	uuidAnsvarlig uuid :='21899b1a-afce-466a-8054-b8268789038b'::uuid;
	uuidRedaktoer1 uuid :='ed97bd42-427b-4f06-a321-de9ba9453dbd'::uuid;
	uuidRedaktoer2 uuid :='e16ed1ea-176a-45ae-99dc-b27d7849e9c9'::uuid;
	uuidRegistrering uuid :='4e5a2388-f620-4279-839c-ec59dd18d0e7'::uuid;
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
	--tempResSoegeord KlasseSoegeordTypeWID[];
	--tempResEgenskaberAttr KlasseEgenskaberAttrTypeWID[];
	
BEGIN


virkEgenskaber :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          '09adacb1-b183-4939-a1ab-a4a3f612bcdb'::uuid,
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkEgenskaberB :=	ROW (
	'[2014-05-13, 2015-01-01)' :: TSTZRANGE,
          '5b3469ab-1f70-4861-8ecf-74fb5975ec2b'::uuid,
          'Bruger',
          'NoteEx7'
          ) :: Virkning
;


virkAnsvarlig :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          '6fedbb57-7dda-415e-856a-ce6ae9402c8a'::uuid,
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkRedaktoer1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          '3f9dd4e2-2155-4301-8078-a4c68e8ffe5a'::uuid,
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkRedaktoer2 :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          '6f544174-856a-408d-86e5-b26f257e3c8f'::uuid,
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;


virkPubliceret:=	ROW (
	'[2015-05-01, infinity)' :: TSTZRANGE,
          '3f9dd4e2-2155-4301-8076-a4c68e8ffe5a'::uuid,
          'Bruger',
          'NoteEx8'
          ) :: Virkning
;

virkPubliceretB:=	ROW (
	'[2014-05-13, 2015-05-01)' :: TSTZRANGE,
          'dac7ae9c-8aa2-4bfa-962b-6fd6354e55f1'::uuid,
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
	'Test Note 4') :: RegistreringBase
	,
ARRAY[klassePubliceret,klassePubliceretB]::KlassePubliceretTilsType[],
ARRAY[klasseEgenskabA,klasseEgenskabB]::KlasseEgenskaberAttrType[],
ARRAY[klasseRelAnsvarlig,klasseRelRedaktoer2,klasseRelRedaktoer1]
) :: KlasseRegistreringType
;

new_uuid := as_create_or_import_klasse(registrering);


registrering := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 54') :: RegistreringBase
	,
ARRAY[klassePubliceret,klassePubliceretB]::KlassePubliceretTilsType[],
ARRAY[klasseEgenskabA,klasseEgenskabB]::KlasseEgenskaberAttrType[],
ARRAY[klasseRelAnsvarlig,klasseRelRedaktoer2,klasseRelRedaktoer1]
) :: KlasseRegistreringType
;

new_uuid := as_create_or_import_klasse(registrering);


virkEgenskaberC :=	ROW (
	'[2015-01-13, infinity)' :: TSTZRANGE,
          '99e031a2-d84e-4431-b3cd-a7e632a385f0'::uuid,
          'Bruger',
          'NoteEx20'
          ) :: Virkning
;

virkEgenskaberD :=	ROW (
	'[2013-06-30, 2014-06-01)' :: TSTZRANGE,
          '86308373-4ef2-41a2-a276-95697567b536'::uuid,
          'Bruger',
          'NoteEx7'
          ) :: Virkning
;

virkEgenskaberE:=	ROW (
	'[2014-08-01, 2014-10-20)' :: TSTZRANGE,
          '951cabb7-8d5c-46ec-906a-17d9cc916e77'::uuid,
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
          '7f9dd4e2-2155-4301-8076-a4c68e8ffe5c'::uuid,
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
  array[klasseEgenskabC,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[],
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

--RAISE NOTICE 'expected_Klasse1_json:%',to_json(expected_Klasse1);
--RAISE NOTICE 'read_Klasse1:%',to_json(read_Klasse1);

RETURN NEXT is(
read_Klasse1,
expected_Klasse1,
'simple read klasse test 1'
);


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
							,ARRAY[klassePubliceretC]--registrering2.tilsPubliceret
							,array[klasseEgenskabD,klasseEgenskabE,
							ROW(
							klasseEgenskabC.brugervendtnoegle,
							klasseEgenskabC.beskrivelse,
							klasseEgenskabC.eksempel,
							klasseEgenskabC.omfang,
							klasseEgenskabC.titel,
							klasseEgenskabC.retskilde,
							klasseEgenskabC.aendringsnotat,
							klasseEgenskabC.integrationsdata,
							null, --array[]::KlasseSoegeordType[], empty array is read as null
 							klasseEgenskabC.virkning 
							)::KlasseEgenskaberAttrType
							]::KlasseEgenskaberAttrType[]
							,registrering2.relationer
						)::KlasseRegistreringType
					]::KlasseRegistreringType[]
			)::KlasseType
;

--RAISE NOTICE 'read_Klasse2_json:%',to_json(read_Klasse2);
--RAISE NOTICE 'expected_Klasse2_json:%',to_json(expected_Klasse2);

RETURN NEXT is(
read_Klasse2,
expected_Klasse2,
'simple read klasse test 2'
);






END;
$$;
