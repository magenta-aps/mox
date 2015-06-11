-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_update_klasse()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid uuid;
	registrering KlasseRegistreringType;
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

	klasse_read1 KlasseType;
	klasse_read2 KlasseType;
	klasse_read3 KlasseType;
	klasse_read4 KlasseType;
	sqlStr1 text;
	sqlStr2 text;
	expected_exception_txt1 text;
	expected_exception_txt2 text;
	--tempResSoegeord KlasseSoegeordTypeWID[];
	--tempResEgenskaberAttr KlasseEgenskaberAttrTypeWID[];
	extraUuid uuid:=uuid_generate_v4();
BEGIN

--------------------------------------------------------------------

sqlStr2:='SELECT as_update_klasse(''' || extraUuid ||'''::uuid,uuid_generate_v4(), ''Test update''::text,''Rettet''::Livscykluskode,null,null,null,''-infinity''::TIMESTAMPTZ)';
expected_exception_txt2:='Unable to update klasse with uuid ['|| extraUuid ||'], being unable to any previous registrations.';

--raise notice 'debug:sqlStr2:%',sqlStr2;
RETURN NEXT throws_ok(sqlStr2,expected_exception_txt2);





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
	'Test Note 4') :: RegistreringBase
	,
ARRAY[klassePubliceret,klassePubliceretB]::KlassePubliceretTilsType[],
ARRAY[klasseEgenskabA,klasseEgenskabB]::KlasseEgenskaberAttrType[],
ARRAY[klasseRelAnsvarlig,klasseRelRedaktoer1,klasseRelRedaktoer2]
) :: KlasseRegistreringType
;

new_uuid := as_create_or_import_klasse(registrering);

klasse_read2:=as_read_Klasse(new_uuid,null,null);

--***************************************
--Update the klasse created above

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



update_reg_id:=as_update_klasse(
  new_uuid, uuid_generate_v4(),'Test update'::text,
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
					a.rel_maal 
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
   				NULL, --klasseEgenskabD.titel,
   				klasseEgenskabD.retskilde,
   				klasseEgenskabD.aendringsnotat,
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
   				klasseEgenskabB.titel, --NOTICE
   				klasseEgenskabD.retskilde,
   				NULL, --notice
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
sqlStr1:='SELECT as_update_klasse(''' || new_uuid || '''::uuid,uuid_generate_v4(), ''Test update''::text,''Rettet''::Livscykluskode,null,null,null,''-infinity''::TIMESTAMPTZ)';
expected_exception_txt1:='Unable to update klasse with uuid [' || new_uuid || '], as the klasse seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [-infinity] does not match the timesamp of latest registration [' || lower(((klasse_read1.registrering[1]).registrering).TimePeriod) || ']).';

--raise notice 'debug:sqlStr1:%',sqlStr1;
RETURN NEXT throws_ok(sqlStr1,expected_exception_txt1);

--------------------------------------------------------------------

BEGIN

	update_reg_id:=as_update_klasse(
	  new_uuid, uuid_generate_v4(),'Test update'::text,
	  'Rettet'::Livscykluskode,          
	  array[klasseEgenskabC,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[],
	  array[klassePubliceretC]::KlassePubliceretTilsType[],
	  array[klasseRelAnsvarlig]::KlasseRelationType[]
	  ,lower(((klasse_read1.registrering[1]).registrering).TimePeriod)
		);

	RETURN NEXT ok(false,'test as_update_klasse - NO exception was triggered by updating klasse with no new data.'); 

	EXCEPTION WHEN data_exception THEN
			RETURN NEXT ok(true,'test as_update_klasse - caught exception, triggered by updating klasse with no new data.'); 
	
END;


--------------------------------------------------------------------

update_reg_id:=as_update_klasse(
	  new_uuid, uuid_generate_v4(),'Test update'::text,
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

--Test if null values are enough to trigger update

BEGIN

update_reg_id:=as_update_klasse(
	  new_uuid, uuid_generate_v4(),'Test update'::text,
	  'Opstaaet'::Livscykluskode,          
	  array[klasseEgenskabC,klasseEgenskabD,klasseEgenskabE]::KlasseEgenskaberAttrType[],
	  array[klassePubliceretC]::KlassePubliceretTilsType[],
	  array[klasseRelAnsvarlig]::KlasseRelationType[]
	  ,lower(((klasse_read3.registrering[1]).registrering).TimePeriod)
		);
	
	RETURN NEXT ok(false,'test as_update_klasse - NO exception was triggered by updating klasse with new livscykluskode, causing an invalid transition.'); 

	EXCEPTION WHEN data_exception THEN
			RETURN NEXT ok(true,'test as_update_klasse - caught exception was triggered by updating klasse with new livscykluskode, causing an invalid transition.'); 

END;


END;
$$;