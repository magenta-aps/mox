-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_update_sag()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid1 uuid;
	registrering sagRegistreringType;
	registreringB sagRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaber Virkning;
	virkPrimaerklasse Virkning;
	virkSekundaerpart1 Virkning;
	virkSekundaerpart2 Virkning;
	virkSekundaerpart3 Virkning;
	virkSekundaerpart4 Virkning;
	virkAndresager1 Virkning;
	virkAndresager2 Virkning;
	virkPubliceret Virkning;
	sagEgenskab sagEgenskaberAttrType;
	sagFremdrift sagFremdriftTilsType;
	sagRelPrimaerklasse sagRelationType;
	sagRelSekundaerpart1 sagRelationType;
	sagRelSekundaerpart2 sagRelationType;
	sagRelSekundaerpart3 sagRelationType;
	sagRelAndresager1 sagRelationType;
	sagRelAndresager2 sagRelationType;
	uuidPrimaerklasse uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	uuidSekundaerpart1 uuid :='b7160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;
	uuidSekundaerpart2 uuid :='08533179-fedb-4aa7-8902-ab34a219eed9'::uuid;
	urnSekundaerpart2 text:='urn:isbn:0451450523'::text;
	urnSekundaerpart3 text:='urn:isbn:8751450519'::text;
	urnSekundaerpart4 text:='urn:isbn:7751450516'::text;
	uuidAndresager1 uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09d'::uuid;
	uuidAndresager2 uuid :='28533179-fedb-4aa7-8902-ab34a219eed1'::uuid;
	uuidRegistrering uuid :='1f368584-4c3e-4ba4-837b-da2b1eee37c9'::uuid;
	virkJournalNotat1 Virkning;
	uuidJournalNotat1  uuid :='97109356-e87e-4b10-ad5d-36de6e3ee011'::uuid;
	sagJournalNotat1 sagRelationType;
	virkJournalNotat5 Virkning;
	uuidJournalNotat5  uuid :='80109356-e87e-4b10-ad5d-36de6e3ee007'::uuid;
	sagJournalNotat5 sagRelationType;
	actual_publiceret_virk virkning;
	actual_publiceret_value sagFremdriftTils;
	actual_publiceret sagFremdriftTilsType;
	actual_relationer sagRelationType[];
	uuid_to_import uuid :='a1819cce-043b-447f-ba5e-92e6a75df918'::uuid;
	uuid_returned_from_import uuid;
	read_Sag1 SagType;
	update_reg_id int;
	update_reg_id_2 int;
	read_sag_relation_1 SagRelationType;
	read_uuidSekundaerpart2 uuid;
	read_rel_index_3 int;
BEGIN


virkEgenskaber :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkPrimaerklasse :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkSekundaerpart1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkSekundaerpart2 :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;


virkSekundaerpart3 :=	ROW (
	'[2014-05-10, 2016-03-20)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx30'
          ) :: Virkning
;

virkSekundaerpart4 :=	ROW (
	'[2013-02-25, 2016-03-21)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx40'
          ) :: Virkning
;


virkPubliceret := ROW (
	'[2015-05-18, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx10'
) :: Virkning
;

virkAndresager1 :=	ROW (
	'[2015-04-10, infinity)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx23'
          ) :: Virkning
;


virkAndresager2 :=	ROW (
	'[2015-06-10, 2016-05-10)' :: TSTZRANGE,
          uuid_generate_v4(),
          'Bruger',
          'NoteEx12'
          ) :: Virkning
;

virkJournalNotat1 :=	ROW (
	'[2014-05-12, infinity)' :: TSTZRANGE,
          uuidJournalNotat1,
          'Bruger',
          'NoteEx1233'
          ) :: Virkning
;

virkJournalNotat5 :=	ROW (
	'[2014-09-12, infinity)' :: TSTZRANGE,
          uuidJournalNotat5,
          'Bruger',
          'NoteEx9'
          ) :: Virkning
;

sagRelPrimaerklasse := ROW (
	'ansvarlig'::sagRelationKode
	,virkPrimaerklasse
	,uuidPrimaerklasse
	,null
	,'Klasse'
	,567 --NOTICE: Should be replace in by import function
	,null --relTypeSpec
	,null --journalNotat
	,null --journalDokumentAttr
) :: sagRelationType
;


sagRelSekundaerpart1 := ROW (
	'sekundaerpart'::sagRelationKode,
		virkSekundaerpart1,
	uuidSekundaerpart1,
	null,
	'Person'
	,768 --NOTICE: Should be replace in by import function
	,null --relTypeSpec
	,null --journalNotat
	,null --journalDokumentAttr
) :: sagRelationType
;



sagRelSekundaerpart2 := ROW (
	'sekundaerpart'::sagRelationKode,
		virkSekundaerpart2,
	null,
	urnSekundaerpart2,
	'Person'
	,800 --NOTICE: Should be replace in by import function
	,null --relTypeSpec
	,null --journalNotat
	,null --journalDokumentAttr
) :: sagRelationType
;



sagRelAndresager1 := ROW (
	'andresager'::sagRelationKode,
		virkAndresager1,
	uuidAndresager1,
	null,
	'Person'
	,7268 --NOTICE: Should be replace in by import function
	,null --relTypeSpec
	,null --journalNotat
	,null --journalDokumentAttr
) :: sagRelationType
;



sagRelAndresager2 := ROW (
	'andresager'::sagRelationKode,
		virkAndresager2,
	uuidAndresager2,
	null,
	'Person'
	,3 --NOTICE: Should be replace in by import function
	,null --relTypeSpec
	,null --journalNotat
	,null --journalDokumentAttr
) :: sagRelationType
;

sagJournalNotat1:= ROW (
					'journalpost'::sagRelationKode,
						virkJournalNotat1,
					uuidJournalNotat1,
					null,
					'Person'
					,4  --NOTICE: Should be replace in by import function
					,'journalnotat'::SagRelationJournalPostSpecifikKode
					, ROW('journal_txt1','journal_notat1','journal_format1')::JournalNotatType --journalNotat
					,ROW(null, ROW(null,null)::OffentlighedundtagetType) ::JournalPostDokumentAttrType --journalDokumentAttr
				);

sagJournalNotat5:= ROW (
					'journalpost'::sagRelationKode,
						virkJournalNotat5,
					uuidJournalNotat5,
					null,
					'Person'
					,20  --NOTICE: Should be replace in by import function
					,'tilakteretdokument'::SagRelationJournalPostSpecifikKode
					, ROW(NULL,NULL,NULL)::JournalNotatType --journalNotat
					,ROW(NULL, ROW('AlternativTitel_1','Hjemmel_1')::OffentlighedundtagetType) ::JournalPostDokumentAttrType --journalDokumentAttr
				);


sagFremdrift := ROW (
virkPubliceret,
'Opstaaet'
):: sagFremdriftTilsType
;


sagEgenskab := ROW (
'brugervendtnoegle_sag_1' --text, 
 ,false --'afleveret_sag_1'-- boolean,
,'beskrivelse_sag_1'-- text,
, 'hjemmel_sag_1'-- text,
, 'kassationskode_sag_1'-- text,
,ROW( 
	'alternativTitel_sag_1'
	,'hjemmel_sag_1'
 )::offentlighedundtagettype
, true --principiel boolean,
,'sagsnummer_1' -- text,
, 'titel_sag_1'-- text,
, 'integrationsdata'-- text,
,virkEgenskaber
) :: sagEgenskaberAttrType
;


registrering := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
ARRAY[sagFremdrift]::sagFremdriftTilsType[],
ARRAY[sagEgenskab]::sagEgenskaberAttrType[],
ARRAY[sagRelPrimaerklasse,sagRelSekundaerpart1,sagRelSekundaerpart2,sagRelAndresager1,sagRelAndresager2,sagJournalNotat1,sagJournalNotat5]
) :: sagRegistreringType
;


new_uuid1 := as_create_or_import_sag(registrering);



sagRelSekundaerpart2 := ROW (
	'sekundaerpart'::sagRelationKode,
		virkSekundaerpart2,
	uuidSekundaerpart2,
	null,
	'Person'
	,2 
	,null --relTypeSpec
	,null --journalNotat
	,null --journalDokumentAttr
) :: sagRelationType
;


update_reg_id:=as_update_sag(
  new_uuid1, '5f368584-4c3e-4ba4-837b-da2b1eee37c4'::uuid,'Test update 20'::text,
  'Rettet'::Livscykluskode,          
  array[sagEgenskab]::SagEgenskaberAttrType[],
  array[sagFremdrift]::SagFremdriftTilsType[],
  array[sagRelSekundaerpart2]::SagRelationType[]
	);

read_Sag1 := as_read_sag(new_uuid1,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

--raise notice 'read_Sag_update 1:%',to_json(read_Sag1);

SELECT
uuid into read_uuidSekundaerpart2 
FROM
unnest(read_Sag1.registrering[1].relationer) a
where
a.indeks=2
and a.relType = 'sekundaerpart'::sagRelationKode
;


RETURN NEXT is(read_uuidSekundaerpart2,uuidSekundaerpart2,'Test update of sag relation based on index #1');


read_Sag1 := as_read_sag(new_uuid1,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);


sagRelSekundaerpart3 := ROW (
	'sekundaerpart'::sagRelationKode,
		virkSekundaerpart2,
	null,
	urnSekundaerpart3,
	'Person'
	,null 
	,null --relTypeSpec
	,null --journalNotat
	,null --journalDokumentAttr
) :: sagRelationType
;

update_reg_id:=as_update_sag(
  new_uuid1, '5f368584-4c3e-4ba4-837b-da2b1eee37c4'::uuid,'Test update 21'::text,
  'Rettet'::Livscykluskode,          
  null,
  null,
  array[sagRelSekundaerpart3]::SagRelationType[]
	);

read_Sag1 := as_read_sag(new_uuid1,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);



SELECT
indeks into read_rel_index_3
FROM
unnest(read_Sag1.registrering[1].relationer) a
where
a.urn = urnSekundaerpart3
and a.relType = 'sekundaerpart'::sagRelationKode
;


RETURN NEXT is(read_rel_index_3,3,'Test update of sag relation based on index #2');


--raise notice 'read_Sag1 update:%',to_json(read_Sag1);

/*******************************************/
--Test if providing empty arguments will trigger exception as expected 
BEGIN

update_reg_id_2:=as_update_sag(
  new_uuid1, '6f368584-4c3e-4ba4-837b-da2b1eee37c6'::uuid,'Test update 30'::text,
  'Rettet'::Livscykluskode,          
  null,
  null,
  null,
  null
	);

RETURN NEXT ok(false,'as_update_sag empty arguments: Should throw MO400 exception');
EXCEPTION  
WHEN sqlstate 'MO400' THEN
	RETURN NEXT ok(true,'as_update_sag empty arguments: Throws MO400 exception (as it should)');

END;





END;
$$;
