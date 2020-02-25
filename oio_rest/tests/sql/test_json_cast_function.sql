-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_json_cast_function()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
virkEgenskaber Virkning;
virkEgenskaberB Virkning;
virkAnsvarlig Virkning;
virkRedaktoer1 Virkning;
virkRedaktoer2 Virkning;
virkPubliceret Virkning;
virkPubliceretB Virkning;
klasseRelAnsvarlig KlasseRelationType;
klasseRelRedaktoer2 KlasseRelationType;
klasserelredaktoer1 KlasseRelationType;
klassePubliceret KlassePubliceretTilsType;
klassePubliceretB KlassePubliceretTilsType;
klasseEgenskabA_Soegeord1 KlasseSoegeordType;
klasseEgenskabA_Soegeord2 KlasseSoegeordType;
klasseEgenskabA KlasseEgenskaberAttrType;
klasseEgenskabB_Soegeord1  KlasseSoegeordType;
klasseEgenskabB_Soegeord2  KlasseSoegeordType;
klasseEgenskabB_Soegeord3 KlasseSoegeordType;
klasseEgenskabB_Soegeord4 KlasseSoegeordType;

klasseEgenskabE_Soegeord1 KlasseSoegeordType;
klasseEgenskabE_Soegeord2 KlasseSoegeordType;
klasseEgenskabE_Soegeord3 KlasseSoegeordType;
klasseEgenskabE_Soegeord4 KlasseSoegeordType;
klasseEgenskabE_Soegeord5 KlasseSoegeordType;

klasseEgenskabB KlasseEgenskaberAttrType;
registreringA KlasseRegistreringType;
new_uuid uuid;
hacked_in_uuid uuid:='5d32f909-327f-479e-b98f-b6e8cbaca1ee'::uuid;
json_result json;
json_expected json;
read_Klasse KlasseType;
uuidAnsvarlig uuid :='ee2616de-91b3-4f7d-8c2d-7e592dbba494'::uuid;
uuidRedaktoer1 uuid :='de08d17d-8b4c-4d7c-a369-ef8a9e4ac32f'::uuid;
uuidRedaktoer2 uuid :='daac7580-3073-429d-a0a7-f5eabf0c35d8'::uuid;
uuidRegistrering uuid :='0cc293df-fa20-414d-8403-d2a95656d93f'::uuid;


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


registreringA := ROW (
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

new_uuid := as_create_or_import_klasse(registreringA);

--json_result:=


--hacks to ease comparison 

insert into klasse (id) values (hacked_in_uuid)
;

update klasse_registrering 
	set registrering.timeperiod = TSTZRANGE('2015-07-30 10:18:42.079076+02','infinity','[)')
	where klasse_id=new_uuid
	AND upper((registrering).timeperiod)='infinity'::TIMESTAMPTZ
;

update klasse_registrering
set klasse_id=hacked_in_uuid
where klasse_id=new_uuid
;

delete from klasse
where id=new_uuid
;


read_Klasse := as_read_Klasse(hacked_in_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

json_result:=read_Klasse::json;
json_expected:=$json_txt${"id":"5d32f909-327f-479e-b98f-b6e8cbaca1ee","registreringer":[{"fratidspunkt":{"tidsstempeldatotid":"2015-07-30T10:18:42.079076+02:00","graenseindikator":true},"tiltidspunkt":{"tidsstempeldatotid":"infinity","graenseindikator":false},"livscykluskode":"Opstaaet","note":"Test Note 54","brugerref":"0cc293df-fa20-414d-8403-d2a95656d93f","attributter":{"klasseegenskaber":[{"brugervendtnoegle":"brugervendt_noegle_A","beskrivelse":"klassebeskrivelse_A","eksempel":"eksempel_A","omfang":"omfang_A","titel":"titel_A","retskilde":"retskilde_A","aendringsnotat":null,"integrationsdata":"integrationsdata_A","soegeord":[{"soegeordidentifikator":"soegeordidentifikator_klasseEgenskabA_Soegeord1","beskrivelse":"beskrivelse_klasseEgenskabA_Soegeord1","soegeordskategori":"soegeordskategori_klasseEgenskabA_Soegeord1"},{"soegeordidentifikator":"soegeordidentifikator_klasseEgenskabA_Soegeord2","beskrivelse":"beskrivelse_klasseEgenskabA_Soegeord2","soegeordskategori":"soegeordskategori_klasseEgenskabA_Soegeord2"}],"virkning":{"timeperiod":"[\"2015-05-12 00:00:00+02\",infinity)","aktoerref":"303514bc-9014-4591-a8a9-22eb37c592f9","aktoertypekode":"Bruger","notetekst":"NoteEx1"}},{"brugervendtnoegle":"brugervendt_noegle_B","beskrivelse":"klassebeskrivelse_B","eksempel":"eksempel_B","omfang":"omfang_B","titel":"titel_B","retskilde":"retskilde_B","aendringsnotat":null,"integrationsdata":"integrationsdata_B","soegeord":[{"soegeordidentifikator":"soegeordidentifikator_klasseEgenskabB_Soegeord1","beskrivelse":"beskrivelse_klasseEgenskabB_Soegeord1","soegeordskategori":"soegeordskategori_klasseEgenskabB_Soegeord1"},{"soegeordidentifikator":"soegeordidentifikator_klasseEgenskabB_Soegeord2","beskrivelse":"beskrivelse_klasseEgenskabB_Soegeord2","soegeordskategori":"soegeordskategori_klasseEgenskabB_Soegeord2"},{"soegeordidentifikator":"soegeordidentifikator_klasseEgenskabB_Soegeord3","beskrivelse":"beskrivelse_klasseEgenskabB_Soegeord3","soegeordskategori":"soegeordskategori_klasseEgenskabB_Soegeord3"},{"soegeordidentifikator":"soegeordidentifikator_klasseEgenskabB_Soegeord4","beskrivelse":"beskrivelse_klasseEgenskabB_Soegeord4","soegeordskategori":"soegeordskategori_klasseEgenskabB_Soegeord4"}],"virkning":{"timeperiod":"[\"2014-05-13 00:00:00+02\",\"2015-01-01 00:00:00+01\")","aktoerref":"858a568b-2ad0-4168-8b83-c48b8238106c","aktoertypekode":"Bruger","notetekst":"NoteEx7"}}]},"tilstande":{"klassepubliceret":[{"virkning":{"timeperiod":"[\"2015-05-01 00:00:00+02\",infinity)","aktoerref":"01cdb20d-1897-4966-9552-0a691f162daf","aktoertypekode":"Bruger","notetekst":"NoteEx8"},"publiceret":"Publiceret"},{"virkning":{"timeperiod":"[\"2014-05-13 00:00:00+02\",\"2015-05-01 00:00:00+02\")","aktoerref":"38efbe3e-3b93-470a-956a-793ca0c8f219","aktoertypekode":"Bruger","notetekst":"NoteEx9"},"publiceret":"IkkePubliceret"}]},"relationer":{"ansvarlig":[{"virkning":{"timeperiod":"[\"2015-05-11 00:00:00+02\",infinity)","aktoerref":"0befe457-cef5-4888-b49c-bbee77e44f99","aktoertypekode":"Bruger","notetekst":"NoteEx2"},"uuid":"ee2616de-91b3-4f7d-8c2d-7e592dbba494","urn":null,"objekttype":null}],"redaktoerer":[{"virkning":{"timeperiod":"[\"2015-05-10 00:00:00+02\",\"2016-05-10 00:00:00+02\")","aktoerref":"1c0ce5a4-02c4-4697-ab39-00b7da0b1f54","aktoertypekode":"Bruger","notetekst":"NoteEx4"},"uuid":"daac7580-3073-429d-a0a7-f5eabf0c35d8","urn":null,"objekttype":null},{"virkning":{"timeperiod":"[\"2015-05-10 00:00:00+02\",infinity)","aktoerref":"f700e686-5bed-45b3-9d13-c09bbdf2ad1a","aktoertypekode":"Bruger","notetekst":"NoteEx3"},"uuid":"de08d17d-8b4c-4d7c-a369-ef8a9e4ac32f","urn":null,"objekttype":null}]}}]}$json_txt$::json; --format json in eclipse or similar to debug/inspect

--raise notice 'read_Klasse - pre json:%',read_Klasse;
--raise notice 'json_result:%',to_json(json_result);
--raise notice 'json_expected:%',to_json(json_expected);


return next ok(json_result::text=json_expected::text,'Json cast test#1');


END;
$$;

