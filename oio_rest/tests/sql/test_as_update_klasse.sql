-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_update_klasse()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid uuid;
	klasseReg KlasseRegistreringType;
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
	uuidAnsvarlig uuid :='ee2616de-91b3-4f7d-8c2d-7e592dbba494'::uuid;
	uuidRedaktoer1 uuid :='de08d17d-8b4c-4d7c-a369-ef8a9e4ac32f'::uuid;
	uuidRedaktoer2 uuid :='daac7580-3073-429d-a0a7-f5eabf0c35d8'::uuid;
	uuidRegistrering uuid :='0cc293df-fa20-414d-8403-d2a95656d93f'::uuid;
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

	klasse_read1 KlasseType;
	klasse_read2 KlasseType;
	klasse_read3 KlasseType;
	klasse_read4 KlasseType;
	klasse_read5 KlasseType;
	klasse_read6 KlasseType;
	klasse_read7 KlasseType;
	klasse_read8 KlasseType;
	klasse_read9 KlasseType;
	klasse_read10 KlasseType;
	klasse_read11 KlasseType;
	klasse_read12 KlasseType;
	klasse_read13 KlasseType;
	klasse_read14 KlasseType;
	klasse_read15 KlasseType;

	sqlStr1 text;
	sqlStr2 text;
	expected_exception_txt1 text;
	expected_exception_txt2 text;
	--tempResSoegeord KlasseSoegeordTypeWID[];
	--tempResEgenskaberAttr KlasseEgenskaberAttrTypeWID[];
	extraUuid uuid:='0e0c250c-8f00-4f8d-850e-5abf8e62012e'::uuid;
BEGIN

--------------------------------------------------------------------

sqlStr2:='SELECT as_update_klasse(''' || extraUuid ||'''::uuid,''2ac63602-6c0a-4531-8a09-ab7633f6dacd''::uuid, ''Test update''::text,''Rettet''::Livscykluskode,null,null,null,''-infinity''::TIMESTAMPTZ)';
expected_exception_txt2:='Unable to update klasse with uuid ['|| extraUuid ||'], being unable to find any previous registrations.';

--raise notice 'debug:sqlStr2:%',sqlStr2;
RETURN NEXT throws_ok(sqlStr2,expected_exception_txt2);





virkEgenskaber :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          '930d5f6f-221d-43d4-af08-b96c9b3821af'::uuid,
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkEgenskaberB :=	ROW (
	'[2014-05-13, 2015-01-01)' :: TSTZRANGE,
          'cbe8142b-bafc-4aaf-89b6-4e90b9e08907'::uuid,
          'Bruger',
          'NoteEx7'
          ) :: Virkning
;


virkAnsvarlig :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          'b0ba2a98-2c2e-4628-b030-e39e25c8166a'::uuid,
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkRedaktoer1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          '65e2fc1f-268f-4c40-bec8-1ba6da4efb1e'::uuid,
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkRedaktoer2 :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          '6cf27f28-8c4a-4fc6-bb6a-6b05322ed67a'::uuid,
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;


virkPubliceret:=	ROW (
	'[2015-05-01, infinity)' :: TSTZRANGE,
          '5df2b2c0-c75b-4e33-aa76-9be94cfcf13c'::uuid,
          'Bruger',
          'NoteEx8'
          ) :: Virkning
;

virkPubliceretB:=	ROW (
	'[2014-05-13, 2015-05-01)' :: TSTZRANGE,
          '2d0d23ea-cf5a-41b9-82e1-219b06c17d9f'::uuid,
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


klasseReg := ROW (
	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
ARRAY[klassePubliceret,klassePubliceretB]::KlassePubliceretTilsType[],
ARRAY[klasseEgenskabA,klasseEgenskabB]::KlasseEgenskaberAttrType[],
ARRAY[klasseRelAnsvarlig,klasseRelRedaktoer1,klasseRelRedaktoer2]
) :: KlasseRegistreringType
;

new_uuid := as_create_or_import_klasse(klasseReg);

klasse_read2:=as_read_Klasse(new_uuid,null,null);

--***************************************
--Update the klasse created above

virkEgenskaberC :=	ROW (
	'[2015-01-13, infinity)' :: TSTZRANGE,
          '7f7405f8-f56c-430c-8ff0-b8c648d1d9f5'::uuid,
          'Bruger',
          'NoteEx20'
          ) :: Virkning
;

virkEgenskaberD :=	ROW (
	'[2013-06-30, 2014-06-01)' :: TSTZRANGE,
          '880e7705-205a-4457-926b-1289632826e1'::uuid,
          'Bruger',
          'NoteEx7'
          ) :: Virkning
;

virkEgenskaberE:=	ROW (
	'[2014-08-01, 2014-10-20)' :: TSTZRANGE,
          '28f44306-e157-426d-9a1a-2e536ef5a369'::uuid,
          'Bruger',
          'NoteEx20'
          ) :: Virkning
;

klasseEgenskabC := ROW (
   'brugervendt_noegle_A',
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
          'cb011ad8-7cf3-406e-a351-faede8d740d4'::uuid,
          'Bruger',
          'NoteEx10'
          ) :: Virkning
;



klassePubliceretC := ROW (
virkPubliceretC,
''::KlassePubliceretTils
):: KlassePubliceretTilsType
;



update_reg_id:=as_update_klasse(
  new_uuid, '8762a443-2f60-49c1-bd8e-ecfdef91d48a'::uuid,'Test update'::text,
  'Rettet'::Livscykluskode,          
  array[klasseEgenskabC,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[],
  array[klassePubliceretC]::KlassePubliceretTilsType[],
  array[klasseRelAnsvarlig]::KlasseRelationType[]
  ,lower(((klasse_read2.registrering[1]).registrering).TimePeriod)
	);


SELECT
array_agg(
			ROW (
					a.rel_type,
					a.virkning,
					a.rel_maal_uuid,
					a.rel_maal_urn,
					a.objekt_type 
				):: KlasseRelationType
		) into actual_relationer
FROM klasse_relation a
JOIN klasse_registrering as b on a.klasse_registrering_id=b.id
WHERE b.id=update_reg_id
;

RETURN NEXT is(
	actual_relationer,
	ARRAY[klasseRelAnsvarlig,klasseRelRedaktoer1,klasseRelRedaktoer2]
,'relations carried over'); --ok, if all relations are present.


SELECT
array_agg(
			ROW (
					a.virkning,
					a.publiceret
				):: KlassePubliceretTilsType
		) into actual_publiceret
FROM klasse_tils_publiceret a
JOIN klasse_registrering as b on a.klasse_registrering_id=b.id
WHERE b.id=update_reg_id
;



RETURN NEXT is(
	actual_publiceret,
ARRAY[
	klassePubliceretC,
	ROW(
		ROW (
				TSTZRANGE('2015-05-01','infinity','()')
				,(klassePubliceret.virkning).AktoerRef
				,(klassePubliceret.virkning).AktoerTypeKode
				,(klassePubliceret.virkning).NoteTekst
			) :: Virkning
		,klassePubliceret.publiceret
		)::KlassePubliceretTilsType,
	ROW(
		ROW (
				TSTZRANGE('2014-05-13','2015-01-01','[)')
				,(klassePubliceretB.virkning).AktoerRef
				,(klassePubliceretB.virkning).AktoerTypeKode
				,(klassePubliceretB.virkning).NoteTekst
			) :: Virkning
		,klassePubliceretB.publiceret
		)::KlassePubliceretTilsType
]::KlassePubliceretTilsType[]
,'publiceret value updated');

/*
select array_agg(
   						ROW(
   							c.id,
   							c.soegeordidentifikator,
   							c.beskrivelse,
   							c.soegeordskategori,
   							c.klasse_attr_egenskaber_id
   							)::KlasseSoegeordTypeWID
						
						order by c.id
   						) into tempResSoegeord
from klasse_attr_egenskaber_soegeord c
;


select array_agg( 
ROW(
	a.id ,
a.brugervendtnoegle ,
a.beskrivelse ,
a.eksempel ,
a.omfang ,
a.titel ,
a.retskilde ,
a.aendringsnotat ,
null,
 a.virkning,
 a.klasse_registrering_id
)::KlasseEgenskaberAttrTypeWID
	) into tempResEgenskaberAttr
from klasse_attr_egenskaber a
;

#raise notice 'tempResEgenskaberAttr:%',to_json(tempResEgenskaberAttr);
#raise notice 'tempResSoegeord:%',to_json(tempResSoegeord);
*/


RETURN NEXT set_eq( 'SELECT

			ROW (
					a.brugervendtnoegle,
					a.beskrivelse,
					a.eksempel,
					a.omfang,
   					a.titel,
   					a.retskilde,
   					a.aendringsnotat,
   					a.integrationsdata,
   					array_agg(
   						CASE WHEN c.id IS NULL THEN NULL
   						ELSE
   						ROW(
   							c.soegeordidentifikator,
   							c.beskrivelse,
   							c.soegeordskategori
   							)::KlasseSoegeordType
						END
						order by c.id
   						),
					a.virkning
				):: KlasseEgenskaberAttrType
		
FROM  klasse_attr_egenskaber a
JOIN klasse_registrering as b on a.klasse_registrering_id=b.id
LEFT JOIN klasse_attr_egenskaber_soegeord c on c.klasse_attr_egenskaber_id=a.id
WHERE b.id=' || update_reg_id::text || '
GROUP BY a.id,a.brugervendtnoegle,a.beskrivelse,a.eksempel,a.omfang,a.titel,a.retskilde,a.aendringsnotat,a.virkning
order by (a.virkning).TimePeriod
'
,   
ARRAY[
		ROW(
				klasseEgenskabD.brugervendtnoegle,
   				klasseEgenskabD.beskrivelse,
   				klasseEgenskabD.eksempel,
   				klasseEgenskabD.omfang,
   				klasseEgenskabD.titel,
   				klasseEgenskabD.retskilde,
   				klasseEgenskabD.aendringsnotat,
   				klasseEgenskabD.integrationsdata,
   				  ARRAY[NULL]::KlasseSoegeordType[], --soegeord --please notice that this should really be NULL, but because of the form of the query above, it will return an array with a null element.
					ROW(
						TSTZRANGE('2013-06-30','2014-05-13','[)'),
						(klasseEgenskabD.virkning).AktoerRef,
						(klasseEgenskabD.virkning).AktoerTypeKode,
						(klasseEgenskabD.virkning).NoteTekst
						)::virkning
			) ::KlasseEgenskaberAttrType
		,
		ROW(
			klasseEgenskabD.brugervendtnoegle,
   				klasseEgenskabD.beskrivelse,
   				klasseEgenskabD.eksempel,
   				klasseEgenskabD.omfang,
   				klasseEgenskabD.titel,
   				klasseEgenskabD.retskilde,
   				NULL, --notice
   				klasseEgenskabD.integrationsdata,
   				  ARRAY[klasseEgenskabB_Soegeord1,klasseEgenskabB_Soegeord2,klasseEgenskabB_Soegeord3,klasseEgenskabB_Soegeord4]::KlasseSoegeordType[], --soegeord
   				ROW(
						TSTZRANGE('2014-05-13','2014-06-01','[)'),
						(klasseEgenskabD.virkning).AktoerRef,
						(klasseEgenskabD.virkning).AktoerTypeKode,
						(klasseEgenskabD.virkning).NoteTekst
						)::virkning
		)::KlasseEgenskaberAttrType
		,
		ROW(
			klasseEgenskabB.brugervendtnoegle,
   				klasseEgenskabB.beskrivelse,
   				klasseEgenskabB.eksempel,
   				klasseEgenskabB.omfang,
   				klasseEgenskabB.titel,
   				klasseEgenskabB.retskilde,
   				klasseEgenskabB.aendringsnotat,
   				klasseEgenskabB.integrationsdata,
   				 ARRAY[klasseEgenskabB_Soegeord1,klasseEgenskabB_Soegeord2,klasseEgenskabB_Soegeord3,klasseEgenskabB_Soegeord4]::KlasseSoegeordType[], --soegeord
					ROW(
						TSTZRANGE('2014-06-01','2014-08-01','[)'),
						(klasseEgenskabB.virkning).AktoerRef,
						(klasseEgenskabB.virkning).AktoerTypeKode,
						(klasseEgenskabB.virkning).NoteTekst
						)::virkning
			)::KlasseEgenskaberAttrType
		,
		ROW(
			klasseEgenskabE.brugervendtnoegle,
   				klasseEgenskabE.beskrivelse,
   				klasseEgenskabE.eksempel,
   				klasseEgenskabE.omfang,
   				klasseEgenskabE.titel,
   				klasseEgenskabE.retskilde,
   				klasseEgenskabB.aendringsnotat, --NOTICE
   				klasseEgenskabE.integrationsdata,
   				 ARRAY[klasseEgenskabE_Soegeord1,klasseEgenskabE_Soegeord2,klasseEgenskabE_Soegeord3,klasseEgenskabE_Soegeord4,klasseEgenskabE_Soegeord5]::KlasseSoegeordType[], --soegeord
					ROW(
						TSTZRANGE('2014-08-01', '2014-10-20','[)'),
						(klasseEgenskabE.virkning).AktoerRef,
						(klasseEgenskabE.virkning).AktoerTypeKode,
						(klasseEgenskabE.virkning).NoteTekst
						)::virkning
			)::KlasseEgenskaberAttrType
		,
		ROW(
			klasseEgenskabB.brugervendtnoegle,
   				klasseEgenskabB.beskrivelse,
   				klasseEgenskabB.eksempel,
   				klasseEgenskabB.omfang,
   				klasseEgenskabB.titel,
   				klasseEgenskabB.retskilde,
   				klasseEgenskabB.aendringsnotat,
   				klasseEgenskabB.integrationsdata,
   				 ARRAY[klasseEgenskabB_Soegeord1,klasseEgenskabB_Soegeord2,klasseEgenskabB_Soegeord3,klasseEgenskabB_Soegeord4]::KlasseSoegeordType[], --soegeord
					ROW(
						TSTZRANGE('2014-10-20','2015-01-01','[)'),
						(klasseEgenskabB.virkning).AktoerRef,
						(klasseEgenskabB.virkning).AktoerTypeKode,
						(klasseEgenskabB.virkning).NoteTekst
						)::virkning
			)::KlasseEgenskaberAttrType
		,

		ROW(
			klasseEgenskabC.brugervendtnoegle,
   				klasseEgenskabC.beskrivelse,
   				klasseEgenskabC.eksempel,
   				klasseEgenskabC.omfang,
   				klasseEgenskabC.titel,
   				klasseEgenskabC.retskilde,
   				klasseEgenskabC.aendringsnotat,
   				klasseEgenskabC.integrationsdata,
   				 ARRAY[NULL]::KlasseSoegeordType[], --soegeord --please notice that this should really be NULL, but because of the form of the query above, it will return an array with a null element.
					ROW(
						TSTZRANGE('2015-01-13','2015-05-12','[)'),
						(klasseEgenskabC.virkning).AktoerRef,
						(klasseEgenskabC.virkning).AktoerTypeKode,
						(klasseEgenskabC.virkning).NoteTekst
						)::virkning
			)::KlasseEgenskaberAttrType
		,
		ROW(
			klasseEgenskabA.brugervendtnoegle, --notice
   				klasseEgenskabA.beskrivelse, --notice
   				klasseEgenskabA.eksempel, --notice
   				klasseEgenskabC.omfang,
   				klasseEgenskabC.titel,
   				klasseEgenskabC.retskilde,
   				klasseEgenskabC.aendringsnotat,
   				klasseEgenskabC.integrationsdata,
   				  ARRAY[NULL]::KlasseSoegeordType[], --soegeord
					ROW(
						TSTZRANGE('2015-05-12','infinity','[)'),
						(klasseEgenskabC.virkning).AktoerRef,
						(klasseEgenskabC.virkning).AktoerTypeKode,
						(klasseEgenskabC.virkning).NoteTekst
						)::virkning
			)::KlasseEgenskaberAttrType

	]::KlasseEgenskaberAttrType[]
    ,    'egenskaber updated' );

--------------------------------------------------------------------

klasse_read1:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);
sqlStr1:='SELECT as_update_klasse(''' || new_uuid || '''::uuid,''b0b79809-b225-4b93-80c7-d18372e7ce18''::uuid, ''Test update''::text,''Rettet''::Livscykluskode,null,null,null,''-infinity''::TIMESTAMPTZ)';

expected_exception_txt1:='Unable to update klasse with uuid [' || new_uuid || '], as the klasse seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [-infinity] does not match the timesamp of latest registration [' || lower(((klasse_read1.registrering[1]).registrering).TimePeriod) || ']).';

--raise notice 'debug:sqlStr1:%',sqlStr1;
RETURN NEXT throws_ok(sqlStr1,expected_exception_txt1);

--------------------------------------------------------------------

BEGIN

	update_reg_id:=as_update_klasse(
	  new_uuid, '8af07c7a-d8f0-439f-af3d-0dbb8b25652f'::uuid,'Test update'::text,
	  'Rettet'::Livscykluskode,          
	  array[klasseEgenskabC,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[],
	  array[klassePubliceretC]::KlassePubliceretTilsType[],
	  array[klasseRelAnsvarlig]::KlasseRelationType[]
	  ,lower(((klasse_read1.registrering[1]).registrering).TimePeriod)
		);

	RETURN NEXT ok(false,'test as_update_klasse - NO exception was triggered by updating klasse with no new data.'); 

	EXCEPTION WHEN sqlstate 'MO400' THEN
			RETURN NEXT ok(true,'test as_update_klasse - caught exception, triggered by updating klasse with no new data.'); 
	
END;


--------------------------------------------------------------------

update_reg_id:=as_update_klasse(
	  new_uuid, 'dc5b848d-da66-45ff-895e-37ea12c7ff5c'::uuid,'Test update'::text,
	  'Passiveret'::Livscykluskode,          
	  array[klasseEgenskabC,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[],
	  array[klassePubliceretC]::KlassePubliceretTilsType[],
	  array[klasseRelAnsvarlig]::KlasseRelationType[]
	  ,lower(((klasse_read1.registrering[1]).registrering).TimePeriod)
		);

klasse_read3:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

	RETURN NEXT ok(((klasse_read3.registrering[1]).registrering).livscykluskode='Passiveret'::Livscykluskode,'test as_update_klasse - update if livscykluskode is only change.');



--------------------------------------------------------------------

BEGIN

update_reg_id:=as_update_klasse(
	  new_uuid, '7518d4d2-5523-47cc-9a15-f5f5db072bc3'::uuid,'Test update'::text,
	  'Opstaaet'::Livscykluskode,          
	  array[klasseEgenskabC,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[],
	  array[klassePubliceretC]::KlassePubliceretTilsType[],
	  array[klasseRelAnsvarlig]::KlasseRelationType[]
	  ,lower(((klasse_read3.registrering[1]).registrering).TimePeriod)
		);
	
	RETURN NEXT ok(false,'test as_update_klasse - NO exception was triggered by updating klasse with new livscykluskode, causing an invalid transition.'); 

	EXCEPTION WHEN SQLSTATE 'MO400' THEN
			RETURN NEXT ok(true,'test as_update_klasse - caught exception was triggered by updating klasse with new livscykluskode, causing an invalid transition.'); 

END;
--------------------------------------------------------------------
--revert latest change in livscykluskode manually 

update klasse_registrering a
	set registrering.livscykluskode= 'Rettet'::Livscykluskode
	where klasse_id=new_uuid
	and upper((registrering).TimePeriod)='infinity'::TIMESTAMPTZ;

/*
update_reg_id:=as_update_klasse(
	  new_uuid, '1847ccbc-de05-401f-a7a8-736a4bc8e301'::uuid,'Test update'::text,
	  'Rettet'::Livscykluskode,          
	  array[klasseEgenskabC,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[],
	  array[klassePubliceretC]::KlassePubliceretTilsType[],
	  array[klasseRelAnsvarlig]::KlasseRelationType[]
	  ,lower(((klasse_read3.registrering[1]).registrering).TimePeriod)
		);


klasse_read4:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);
*/

--Test null egenskaber array will not trigger update
BEGIN

update_reg_id:=as_update_klasse(
	  new_uuid, 'cd7473d3-6ffd-4971-81cb-90b91dfe17fb'::uuid,'Test update'::text,
	  'Rettet'::Livscykluskode,          
	  null,--klasse_read4.registrering[1].attrEgenskaber,
	  klasse_read3.registrering[1].tilsPubliceret,
	  klasse_read3.registrering[1].relationer
	  ,lower(((klasse_read3.registrering[1]).registrering).TimePeriod)
		);
	
		RETURN NEXT ok(false,'Test null egenskaber array will not trigger update#1');
	EXCEPTION WHEN sqlstate 'MO400' THEN
		RETURN NEXT ok(true,'Test null egenskaber array will not trigger update #1');
END;

klasse_read6:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

RETURN NEXT ok(((klasse_read3.registrering[1]).registrering).TimePeriod=((klasse_read6.registrering[1]).registrering).TimePeriod,'Test null egenskaber array will not trigger update #2');

--Test clearing egenskaber

update_reg_id:=as_update_klasse(
	  new_uuid, 'cd7473d3-5ffd-4971-81cb-90b91dfe17fb'::uuid,'Test update'::text,
	  'Rettet'::Livscykluskode,          
	  array[]::KlasseEgenskaberAttrType[],--klasse_read4.registrering[1].attrEgenskaber,
	  klasse_read6.registrering[1].tilsPubliceret,
	  klasse_read6.registrering[1].relationer
	  ,lower(((klasse_read6.registrering[1]).registrering).TimePeriod)
		);

klasse_read5:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

RETURN NEXT ok(lower(((klasse_read5.registrering[1]).registrering).TimePeriod)<>lower(((klasse_read3.registrering[1]).registrering).TimePeriod),'Test if clearing egenskaber works.#1');
RETURN NEXT ok( coalesce(array_length((klasse_read5.registrering[1]).attrEgenskaber,1),0)=0,'Test if clearing egenskaber works.#2');

-------------------------------------------

--Test null tilstand publiceret array will not trigger update
BEGIN

update_reg_id:=as_update_klasse(
	  new_uuid, 'cd7473d3-6ffd-4971-81cb-90b91dfe17fb'::uuid,'Test update'::text,
	  'Rettet'::Livscykluskode,          
	  klasse_read5.registrering[1].attrEgenskaber,
	  null,--klasse_read4.registrering[1].tilsPubliceret,
	  klasse_read5.registrering[1].relationer
	  ,lower(((klasse_read5.registrering[1]).registrering).TimePeriod)
		);
	
		RETURN NEXT ok(false,'Test null tilstand publiceret array will not trigger update #1');
	EXCEPTION WHEN SQLSTATE 'MO400' THEN
		RETURN NEXT ok(true,'Test null tilstand publiceret array will not trigger update #1');
END;


klasse_read7:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

RETURN NEXT ok(((klasse_read7.registrering[1]).registrering).TimePeriod=((klasse_read5.registrering[1]).registrering).TimePeriod,'Test null tilstand publiceret array will not trigger update #2');


--Test clearing tilstand publiceret
--raise notice 'debug 50 klasse_read7:%',to_json(klasse_read7);
RETURN NEXT ok( coalesce(array_length((klasse_read7.registrering[1]).tilsPubliceret,1),0)=3,'Test if clearing tilstand publiceret  works.#0');

update_reg_id:=as_update_klasse(
	  new_uuid, 'cd7473d3-6ffd-4971-81cb-90b91dfe17fb'::uuid,'Test update'::text,
	  'Rettet'::Livscykluskode,          
	  klasse_read7.registrering[1].attrEgenskaber,
	  array[]::KlassePubliceretTilsType[],--klasse_read4.registrering[1].tilsPubliceret,
	  klasse_read7.registrering[1].relationer
	  ,lower(((klasse_read7.registrering[1]).registrering).TimePeriod)
		);

klasse_read8:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);


RETURN NEXT ok(((klasse_read7.registrering[1]).registrering).TimePeriod<>((klasse_read8.registrering[1]).registrering).TimePeriod,'Test if clearing tilstand publiceret works.#1');
RETURN NEXT ok( coalesce(array_length((klasse_read8.registrering[1]).tilsPubliceret,1),0)=0,'Test if clearing tilstand publiceret  works.#2');

-------------------------------------------

--restore "some" tilstande
update_reg_id:=as_update_klasse(
	  new_uuid, '1847ccbc-de05-401f-a7a8-736a4bc8e301'::uuid,'Test update'::text,
	  'Rettet'::Livscykluskode,          
	  array[klasseEgenskabC,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[],
	  array[klassePubliceretC]::KlassePubliceretTilsType[],
	  array[klasseRelAnsvarlig]::KlasseRelationType[]
	  ,lower(((klasse_read8.registrering[1]).registrering).TimePeriod)
		);


klasse_read9:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);


-------------------------------------------

--Test null relationer array will not trigger update
BEGIN

update_reg_id:=as_update_klasse(
	  new_uuid, 'cd7473d3-6ffd-4971-81cb-90b91dfe17fb'::uuid,'Test update'::text,
	  'Rettet'::Livscykluskode,          
	  klasse_read9.registrering[1].attrEgenskaber,
	  klasse_read9.registrering[1].tilsPubliceret,
	  null--klasse_read8.registrering[1].relationer
	  ,lower(((klasse_read9.registrering[1]).registrering).TimePeriod)
		);
	
		RETURN NEXT ok(false,'Test null relationer array will not trigger update #1');
	EXCEPTION WHEN SQLSTATE 'MO400' THEN
		RETURN NEXT ok(true,'Test null relationer array will not trigger update #1');
END;


klasse_read10:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

RETURN NEXT ok(((klasse_read10.registrering[1]).registrering).TimePeriod=((klasse_read9.registrering[1]).registrering).TimePeriod,'Test null relationer array will not trigger update #2');


--Test clearing relationer
--raise notice 'debug klasse_read10:%',to_json(klasse_read10);
RETURN NEXT ok( coalesce(array_length((klasse_read10.registrering[1]).relationer,1),0)=3,'Test if clearing relationer  works.#0');

update_reg_id:=as_update_klasse(
	  new_uuid, 'cd7473d3-6ffd-4971-81cb-90b91dfe17fb'::uuid,'Test if clearing relationer works'::text,
	  'Rettet'::Livscykluskode,          
	  klasse_read10.registrering[1].attrEgenskaber,
	  klasse_read10.registrering[1].tilsPubliceret,
	  array[]::KlasseRelationType[] --klasse_read10.registrering[1].relationer
	  ,lower(((klasse_read10.registrering[1]).registrering).TimePeriod)
		);

klasse_read11:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);


RETURN NEXT ok(((klasse_read10.registrering[1]).registrering).TimePeriod<>((klasse_read11.registrering[1]).registrering).TimePeriod,'Test if clearing relationer works.#1');
RETURN NEXT ok( coalesce(array_length((klasse_read11.registrering[1]).relationer,1),0)=0,'Test if clearing relationer  works.#2');

-----------------------------------
--restore "a" relation
update_reg_id:=as_update_klasse(
	  new_uuid, '1847ccbc-de05-401f-a7a8-736a4bc8e301'::uuid,'Restore relation'::text,
	  'Rettet'::Livscykluskode,          
	  array[klasseEgenskabC,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[],
	  array[klassePubliceretC]::KlassePubliceretTilsType[],
	  array[klasseRelAnsvarlig]::KlasseRelationType[]
	  ,lower(((klasse_read11.registrering[1]).registrering).TimePeriod)
		);
klasse_read12:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);


-----------------------------------
--test that nulling a single field will not trigger an update

BEGIN

update_reg_id:=as_update_klasse(
	  new_uuid, uuid_generate_v4(),'Test update'::text,
	  'Rettet'::Livscykluskode,          
	  array[
	  ROW(
		   'brugervendt_noegle_A',
		   NULL, --'klassebeskrivelse_text1',
		   NULL, --'eksempel_text1',
		   NULL, --NOTICE!!	'omfang_C', 
		   'titel_C',
		   'retskilde_C',
		   'aendringsnotat_C',
		   'integrationsdata_C',
		   ARRAY[]::KlasseSoegeordType[], --soegeord
		   virkEgenskaberC
	  )::KlasseEgenskaberAttrType
	  ,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[],
	  array[klassePubliceretC]::KlassePubliceretTilsType[],
	  array[klasseRelAnsvarlig]::KlasseRelationType[]
	  ,lower(((klasse_read12.registrering[1]).registrering).TimePeriod)
		);

RETURN NEXT ok(false,'test as_update_klasse - Test that nulling a single attr egenskab field will not trigger an update #1'); 

	EXCEPTION WHEN SQLSTATE 'MO400' THEN
			RETURN NEXT ok(true,'test as_update_klasse - Test that nulling a single attr egenskab field will not trigger an update #1.'); 

--TODO: Test if nulling a value is enough to trigger update

klasse_read13:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);


RETURN NEXT ok(((klasse_read13.registrering[1]).registrering).TimePeriod=((klasse_read12.registrering[1]).registrering).TimePeriod,'Test that nulling a single attr egenskab field will not trigger an update #2');


END;

--------------------------------------------------------------------
--test that giving a previously null field a value will trigger an update


update_reg_id:=as_update_klasse(
	  new_uuid, uuid_generate_v4(),'Test update'::text,
	  'Rettet'::Livscykluskode,          
	  array[
	  ROW(
		   'brugervendt_noegle_text1',
		   NULL, --'klassebeskrivelse_text1',
		   'eksempel_textC_new', --NOTICE--'eksempel_text1',
		   'omfang_C', -- 'omfang_C', 
		   'titel_C',
		   'retskilde_C',
		   'aendringsnotat_C',
		   'integrationsdata_C',
		   ARRAY[]::KlasseSoegeordType[], --soegeord
		   virkEgenskaberC
	  )::KlasseEgenskaberAttrType
	  ,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[],
	  array[klassePubliceretC]::KlassePubliceretTilsType[],
	  array[klasseRelAnsvarlig]::KlasseRelationType[]
	  ,lower(((klasse_read13.registrering[1]).registrering).TimePeriod)
		);

klasse_read14:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

--raise notice 'debug klasse_read13:%',to_json(klasse_read13);
--raise notice 'debug klasse_read14:%',to_json(klasse_read14);

RETURN NEXT ok((klasse_read14.registrering[1]).attrEgenskaber[3].eksempel='eksempel_textC_new','Test that giving a previously null field a value will trigger an update');


--------------------------------------------------------------------
--test that giving field a blank will trigger an update


update_reg_id:=as_update_klasse(
	  new_uuid, uuid_generate_v4(),'Test update'::text,
	  'Rettet'::Livscykluskode,          
	  array[
	  ROW(
		   'brugervendt_noegle_text1',
		   NULL, --'klassebeskrivelse_text1',
		   '', --NOTICE--'eksempel_text1',
		   'omfang_C', -- 'omfang_C', 
		   'titel_C',
		   'retskilde_C',
		   'aendringsnotat_C',
		   'integrationsdata_C',
		   ARRAY[]::KlasseSoegeordType[], --soegeord
		   virkEgenskaberC
	  )::KlasseEgenskaberAttrType
	  ,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[],
	  array[klassePubliceretC]::KlassePubliceretTilsType[],
	  array[klasseRelAnsvarlig]::KlasseRelationType[]
	  ,lower(((klasse_read14.registrering[1]).registrering).TimePeriod)
		);

klasse_read15:=as_read_Klasse(new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

--raise notice 'debug klasse_read13:%',to_json(klasse_read13);
--raise notice 'debug klasse_read14:%',to_json(klasse_read14);

RETURN NEXT ok((klasse_read15.registrering[1]).attrEgenskaber[3].eksempel='','Test that giving field a blank will trigger an update');


--------------------------------------------------------------------



virkEgenskaber :=	ROW (
	'[2014-05-12, 2015-05-13]' :: TSTZRANGE,
          '930d5f6f-221d-43d4-af08-b96c9b3821af'::uuid,
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkEgenskaberB :=	ROW (
	'[2015-05-13, infinity)' :: TSTZRANGE,
          'cbe8142b-bafc-4aaf-89b6-4e90b9e08907'::uuid,
          'Bruger',
          'NoteEx7'
          ) :: Virkning
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


BEGIN

update_reg_id:=as_update_klasse(
	  new_uuid, '7518d4d2-5523-47cc-9a15-f5f5db072bc3'::uuid,'Test update 89'::text,
	  'Rettet'::Livscykluskode,          
	  array[klasseEgenskabA,klasseEgenskabB]::KlasseEgenskaberAttrType[],
	  array[klassePubliceretC]::KlassePubliceretTilsType[],
	  array[klasseRelAnsvarlig]::KlasseRelationType[]
	  ,lower(((klasse_read15.registrering[1]).registrering).TimePeriod)
		);
	
	RETURN NEXT ok(false,'test as_update_klasse - NO exception was triggered by updating klasse with egenskaber with overlapping virkning.'); 

	EXCEPTION WHEN SQLSTATE 'MO400' THEN
			RETURN NEXT ok(true,'test as_update_klasse - caught exception triggered by updating klasse with egenskaber with overlapping virkning.'); 

END;



END;
$$;
