-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
	uuidAnsvarlig uuid :=uuid_generate_v4();
	uuidRedaktoer1 uuid :=uuid_generate_v4();
	uuidRedaktoer2 uuid :=uuid_generate_v4();
	uuidRegistrering uuid :=uuid_generate_v4();
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



klasseRelAnsvarlig := ROW (
	'ansvarlig'::KlasseRelationKode,
		virkAnsvarlig,
	uuidAnsvarlig
) :: KlasseRelationType
;


klasseRelRedaktoer1 := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer1,
	uuidRedaktoer1
) :: KlasseRelationType
;



klasseRelRedaktoer2 := ROW (
	'redaktoerer'::KlasseRelationKode,
		virkRedaktoer2,
	uuidRedaktoer2
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
ARRAY[klasseRelAnsvarlig,klasseRelRedaktoer1,klasseRelRedaktoer2]
) :: KlasseRegistreringType
;

new_uuid := as_create_or_import_klasse(registrering);


virkEgenskaberC :=	ROW (
	'[2015-01-13, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx20'
          ) :: Virkning
;

virkEgenskaberD :=	ROW (
	'[2013-06-30, 2014-06-01)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx7'
          ) :: Virkning
;

virkEgenskaberE:=	ROW (
	'[2014-08-01, 2014-10-20)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx20'
          ) :: Virkning
;

klasseEgenskabC := ROW (
   NULL,--'brugervendt_noegle_text1',
   NULL, --'klassebeskrivelse_text1',
   NULL,--'eksempel_text1',
	'omfang_C',
   'titel_C',
   'retskilde_C',
   'aendringsnotat_C',
   ARRAY[]::KlasseSoegeordType[], --soegeord
   virkEgenskaberC
) :: KlasseEgenskaberAttrType
;

klasseEgenskabD := ROW (
'brugervendt_noegle_D',
   'klassebeskrivelse_D',
   'eksempel_D',
   'omfang_D',
   NULL,-- 'titel_D',
   'retskilde_D',
   NULL, --aendringsnotat
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
    ARRAY[klasseEgenskabE_Soegeord1,klasseEgenskabE_Soegeord2,klasseEgenskabE_Soegeord3,klasseEgenskabE_Soegeord4,klasseEgenskabE_Soegeord5]::KlasseSoegeordType[], --soegeord
   virkEgenskaberE
) :: KlasseEgenskaberAttrType
;

virkPubliceretC:=	ROW (
	'[2015-01-01, 2015-05-01]' :: TSTZRANGE,
          uuid_generate_v4(),
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
							,registrering2.tilsPubliceret
							,array[
							ROW(
							klasseEgenskabC.brugervendtnoegle,
							klasseEgenskabC.beskrivelse,
							klasseEgenskabC.eksempel,
							klasseEgenskabC.omfang,
							klasseEgenskabC.titel,
							klasseEgenskabC.retskilde,
							klasseEgenskabC.aendringsnotat,
							NULL, --notice: empty array for soegeord get read as null
 							klasseEgenskabC.virkning 
							)::KlasseEgenskaberAttrType
							,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[]
							,registrering2.relationer
						)::KlasseRegistreringType
					]::KlasseRegistreringType[]
			)::KlasseType
;




--raise notice 'expected_klasses1:%',to_json(expected_klasses1);
--raise notice 'actual_klasses1:%',to_json(actual_klasses1);
/*
(klasse_uuids uuid[],
  registrering_tstzrange tstzrange,
  virkning_tstzrange tstzrange)
*/

select array_agg(a.* order by a.id) from as_list_klasse(array[new_uuid]::uuid[],null,null) as a     into actual_klasses_1;

RAISE NOTICE 'actual_klasses_1:%',to_json(actual_klasses_1);
RAISE NOTICE 'expected_Klasse1_arr_json:%',to_json(ARRAY[expected_Klasse1]);



RETURN NEXT is(
	actual_klasses_1,
	ARRAY[expected_Klasse1],	
	'list klasse test 1');


select array_agg(a.* order by a.id) from as_list_klasse(array[new_uuid2]::uuid[],null,null) as a     into actual_klasses_2;


RETURN NEXT is(
	actual_klasses_2,
	ARRAY[expected_Klasse2],	
	'list klasse test 2');





select array_agg(a.* order by a.id) from as_list_klasse(array[new_uuid,new_uuid2]::uuid[],null,null) as a     into actual_klasses_3;


select array_agg(a.* order by a.id) from unnest(ARRAY[expected_Klasse1,expected_Klasse2]) as a into expected_klasses_3;

RETURN NEXT is(
	actual_klasses_3,
	expected_klasses_3,	
	'list klasse test 3');


END;
$$;