-- Copyright (C) 2015 Magenta ApS, https://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_search_sag()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid1 uuid;
	registrering1 sagRegistreringType;
	new_uuid2 uuid;
	registrering2 sagRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaber Virkning;
	virkPrimaerklasse Virkning;
	virkSekundaerpart1 Virkning;
	virkSekundaerpart2 Virkning;
	virkAndresager1 Virkning;
	virkAndresager2 Virkning;
	virkPubliceret Virkning;
	sagEgenskab sagEgenskaberAttrType;
	sagFremdrift sagFremdriftTilsType;
	sagRelPrimaerklasse sagRelationType;
	sagRelSekundaerpart1 sagRelationType;
	sagRelSekundaerpart2 sagRelationType;
	sagRelAndresager1 sagRelationType;
	sagRelAndresager2 sagRelationType;
	virkJournalNotat1 Virkning;
	uuidJournalNotat1  uuid :='97109356-e87e-4b10-ad5d-36de6e3ee011'::uuid;
	sagJournalNotat1 sagRelationType;
	virkJournalNotat2 Virkning;
	uuidJournalNotat2  uuid :='82109356-e87e-4b10-ad5d-36de6e3ee082'::uuid;
	sagJournalNotat2 sagRelationType;
	virkJournalNotat3 Virkning;
	uuidJournalNotat3  uuid :='27109356-e87e-4b10-ad5d-36de6e3ee015'::uuid;
	sagJournalNotat3 sagRelationType;

	virkJournalNotat4 Virkning;
	uuidJournalNotat4  uuid :='62109356-e87e-4b10-ad5d-36de6e3ee019'::uuid;
	sagJournalNotat4 sagRelationType;
	virkJournalNotat5 Virkning;
	uuidJournalNotat5  uuid :='80109356-e87e-4b10-ad5d-36de6e3ee007'::uuid;
	sagJournalNotat5 sagRelationType;

	virkJournalNotat6 Virkning;
	uuidJournalNotat6  uuid :='90109356-e87e-4b10-ad5d-36de6e3ee009'::uuid;
	sagJournalNotat6 sagRelationType;

	virkJournalNotat7 Virkning;
	uuidJournalNotat7  uuid :='92109356-e87e-4b10-ad5d-36de6e3ee011'::uuid;
	sagJournalNotat7 sagRelationType;

	uuidPrimaerklasse uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	uuidSekundaerpart1 uuid :='b7160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;


	--uuidSekundaerpart2 uuid :='08533179-fedb-4aa7-8902-ab34a219eed9'::uuid;
	urnSekundaerpart2 text:='urn:isbn:0451450523'::text;
	uuidAndresager1 uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09d'::uuid;
	uuidAndresager2 uuid :='28533179-fedb-4aa7-8902-ab34a219eed1'::uuid;
	uuidRegistrering uuid :='1f368584-4c3e-4ba4-837b-da2b1eee37c9'::uuid;
	actual_publiceret_virk virkning;
	actual_publiceret_value sagFremdriftTils;
	actual_publiceret sagFremdriftTilsType;
	actual_relationer sagRelationType[];
	uuid_to_import uuid :='a1819cce-043b-447f-ba5e-92e6a75df918'::uuid;
	uuid_returned_from_import uuid;
	read_Sag1 SagType;
	expected_sag1 SagType;

	actual_search_res_1 uuid[];
	actual_search_res_2 uuid[];
	actual_search_res_3 uuid[];
	actual_search_res_4 uuid[];
	actual_search_res_5 uuid[];
	actual_search_res_6 uuid[];

	expected_search_res_1 uuid[];
	expected_search_res_2 uuid[];
	expected_search_res_3 uuid[];
	expected_search_res_4 uuid[];
	expected_search_res_5 uuid[];
	expected_search_res_6 uuid[];

BEGIN




virkJournalNotat1 :=	ROW (
	'[2014-05-12, infinity)' :: TSTZRANGE,
          uuidJournalNotat1,
          'Bruger',
          'NoteEx1233'
          ) :: Virkning
;


virkJournalNotat2 :=	ROW (
	'[2014-06-12, infinity)' :: TSTZRANGE,
          uuidJournalNotat2,
          'Bruger',
          'NoteEx12331'
          ) :: Virkning
;

virkJournalNotat3 :=	ROW (
	'[2014-07-12, infinity)' :: TSTZRANGE,
          uuidJournalNotat3,
          'Bruger',
          'NoteEx12332'
          ) :: Virkning
;

virkJournalNotat4 :=	ROW (
	'[2014-08-12, infinity)' :: TSTZRANGE,
          uuidJournalNotat4,
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkJournalNotat5 :=	ROW (
	'[2014-09-12, infinity)' :: TSTZRANGE,
          uuidJournalNotat5,
          'Bruger',
          'NoteEx9'
          ) :: Virkning
;

virkJournalNotat6 :=	ROW (
	'[2014-02-12, infinity)' :: TSTZRANGE,
          uuidJournalNotat5,
          'Bruger',
          'NoteEx9'
          ) :: Virkning
;

virkJournalNotat7 :=	ROW (
	'[2014-09-19, infinity)' :: TSTZRANGE,
          uuidJournalNotat5,
          'Bruger',
          'NoteEx9'
          ) :: Virkning
;


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
	,null 
	,ROW(null,null,null)::JournalNotatType 
	,ROW(null, ROW(null,null)::OffentlighedundtagetType) ::JournalPostDokumentAttrType --journalDokumentAttr
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


sagJournalNotat2:= ROW (
					'journalpost'::sagRelationKode,
						virkJournalNotat2,
					uuidJournalNotat2,
					null,
					'Person'
					,5  --NOTICE: Should be replace in by import function
					,'journalnotat'::SagRelationJournalPostSpecifikKode
					, ROW(NULL,NULL,'journal_format2')::JournalNotatType --journalNotat
					,null --journalDokumentAttr
				);


sagJournalNotat3:= ROW (
					'journalpost'::sagRelationKode,
						virkJournalNotat3,
					uuidJournalNotat3,
					null,
					'Person'
					,6  --NOTICE: Should be replace in by import function
					,'journalnotat'::SagRelationJournalPostSpecifikKode
					, ROW(NULL,NULL,NULL)::JournalNotatType --journalNotat
					,ROW(null, ROW(null,null)::OffentlighedundtagetType) ::JournalPostDokumentAttrType --journalDokumentAttr
				);


sagJournalNotat4:= ROW (
					'journalpost'::sagRelationKode,
						virkJournalNotat4,
					uuidJournalNotat4,
					null,
					'Person'
					,19  --NOTICE: Should be replace in by import function
					,'vedlagtdokument'::SagRelationJournalPostSpecifikKode
					, ROW(NULL,NULL,NULL)::JournalNotatType --journalNotat
					,ROW('vedlagt_titel_1', ROW(null,null)::OffentlighedundtagetType) ::JournalPostDokumentAttrType --journalDokumentAttr
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

sagJournalNotat6:= ROW (
					'journalpost'::sagRelationKode,
						virkJournalNotat6,
					uuidJournalNotat6,
					null,
					'Person'
					,21  --NOTICE: Should be replace in by import function
					,'tilakteretdokument'::SagRelationJournalPostSpecifikKode
					, ROW(NULL,NULL,NULL)::JournalNotatType --journalNotat
					,ROW(NULL, ROW('AlternativTitel_2',NULL)::OffentlighedundtagetType) ::JournalPostDokumentAttrType --journalDokumentAttr
				);

sagJournalNotat7:= ROW (
					'journalpost'::sagRelationKode,
						virkJournalNotat7,
					uuidJournalNotat7,
					null,
					'Person'
					,22  --NOTICE: Should be replace in by import function
					,'tilakteretdokument'::SagRelationJournalPostSpecifikKode
					, ROW(NULL,NULL,NULL)::JournalNotatType --journalNotat
					,ROW(NULL, ROW(NULL,'Hjemmel_3')::OffentlighedundtagetType) ::JournalPostDokumentAttrType --journalDokumentAttr
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
,virkEgenskaber
) :: sagEgenskaberAttrType
;


registrering1 := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
ARRAY[sagFremdrift]::sagFremdriftTilsType[],
ARRAY[sagEgenskab]::sagEgenskaberAttrType[],
ARRAY[sagRelPrimaerklasse,sagRelSekundaerpart1,sagRelSekundaerpart2,sagRelAndresager1,sagRelAndresager2,sagJournalNotat2,sagJournalNotat3,sagJournalNotat4,sagJournalNotat5,sagJournalNotat6]
) :: sagRegistreringType
;


new_uuid1 := as_create_or_import_sag(registrering1);



/************************************/

registrering2 := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 4') :: RegistreringBase
	,
ARRAY[sagFremdrift]::sagFremdriftTilsType[],
ARRAY[sagEgenskab]::sagEgenskaberAttrType[],
ARRAY[sagRelPrimaerklasse,sagRelSekundaerpart1,sagRelSekundaerpart2,sagRelAndresager1,sagRelAndresager2,sagJournalNotat1,sagJournalNotat2,sagJournalNotat4,sagJournalNotat7]
) :: sagRegistreringType
;


new_uuid2 := as_create_or_import_sag(registrering2);

/************************************************/

expected_search_res_1:=array[new_uuid1,new_uuid2];

actual_search_res_1:=as_search_sag(null,null,
		ROW(
				null --registrering RegistreringBase,
				,array[] :: SagFremdriftTilsType[]
				,null --attrEgenskaber SagEgenskaberAttrType[],
				,ARRAY[
				ROW (
					'journalpost'::sagRelationKode
					,null --	virkJournalNotat4
					,null --uuidJournalNotat4
					,null
					,null --'Person'
					,null --19  --NOTICE: Should be replace in by import function
					,'vedlagtdokument'::SagRelationJournalPostSpecifikKode
					,null-- ROW(NULL,NULL,NULL)::JournalNotatType --journalNotat
					,ROW('vedlagt_titel_1', null) ::JournalPostDokumentAttrType --journalDokumentAttr
				) ::sagRelationType
				] ::sagRelationType[]
			)::SagRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_1 @> actual_search_res_1 and actual_search_res_1 @>expected_search_res_1 and array_length(expected_search_res_1,1)=array_length(actual_search_res_1,1), 'search sag reltion extra meta data #1.');

/************************************************/
expected_search_res_2:=array[]::uuid[];

actual_search_res_2:=as_search_sag(null,null,
		ROW(
				null --registrering RegistreringBase,
				,array[] :: SagFremdriftTilsType[]
				,null --attrEgenskaber SagEgenskaberAttrType[],
				,ARRAY[
				ROW (
					'journalpost'::sagRelationKode
					,null --	virkJournalNotat4
					,null --uuidJournalNotat4
					,null
					,null --'Person'
					,null --29  --NOTICE: Should be replace in by import function
					,'vedlagtdokument'::SagRelationJournalPostSpecifikKode
					,null-- ROW(NULL,NULL,NULL)::JournalNotatType --journalNotat
					,ROW('vedlagt_titel_2', null) ::JournalPostDokumentAttrType --journalDokumentAttr
				) ::sagRelationType
				] ::sagRelationType[]
			)::SagRegistreringType	
		,null
);

RETURN NEXT ok(coalesce(array_length(expected_search_res_2,1),0)=coalesce(array_length(actual_search_res_2,1),0), 'search sag reltion extra meta data #2.');



/************************************************/
expected_search_res_3:=array[new_uuid2]::uuid[];

actual_search_res_3:=as_search_sag(null,null,
		ROW(
				null --registrering RegistreringBase,
				,array[] :: SagFremdriftTilsType[]
				,null --attrEgenskaber SagEgenskaberAttrType[],
				,ARRAY[
				ROW (
					'journalpost'::sagRelationKode
					,null --	virkJournalNotat4
					,null --uuidJournalNotat4
					,null
					,null --'Person'
					,null --39  --NOTICE: Should be replace in by import function
					,'tilakteretdokument'::SagRelationJournalPostSpecifikKode
					,null-- ROW(NULL,NULL,NULL)::JournalNotatType --journalNotat
					,ROW(NULL, ROW(NULL,'Hjemmel_3')::OffentlighedundtagetType) ::JournalPostDokumentAttrType --journalDokumentAttr
				) ::sagRelationType
				] ::sagRelationType[]
			)::SagRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_3 @> actual_search_res_3 and actual_search_res_3 @>expected_search_res_3 and coalesce(array_length(expected_search_res_3,1),0)=coalesce(array_length(actual_search_res_3,1),0), 'search sag reltion extra meta data #3.');

/************************************************/
expected_search_res_4:=array[new_uuid1]::uuid[];

actual_search_res_4:=as_search_sag(null,null,
		ROW(
				null --registrering RegistreringBase,
				,array[] :: SagFremdriftTilsType[]
				,null --attrEgenskaber SagEgenskaberAttrType[],
				,ARRAY[
				ROW (
					'journalpost'::sagRelationKode
					,null --	virkJournalNotat4
					,null --uuidJournalNotat4
					,null
					,null --'Person'
					,null --49  --NOTICE: Should be replace in by import function
					,'tilakteretdokument'::SagRelationJournalPostSpecifikKode
					,null-- ROW(NULL,NULL,NULL)::JournalNotatType --journalNotat
					,ROW(NULL, ROW('AlternativTitel_1',null)::OffentlighedundtagetType) ::JournalPostDokumentAttrType --journalDokumentAttr
				) ::sagRelationType
				] ::sagRelationType[]
			)::SagRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_4 @> actual_search_res_4 and actual_search_res_4 @>expected_search_res_4 and coalesce(array_length(expected_search_res_4,1),0)=coalesce(array_length(actual_search_res_4,1),0), 'search sag reltion extra meta data #4.');


/************************************************/
expected_search_res_5:=array[new_uuid2]::uuid[];

actual_search_res_5:=as_search_sag(null,null,
		ROW(
				null --registrering RegistreringBase,
				,array[] :: SagFremdriftTilsType[]
				,null --attrEgenskaber SagEgenskaberAttrType[],
				,ARRAY[
				ROW (
					'journalpost'::sagRelationKode
					,null--	virkJournalNotat1,
					,null--uuidJournalNotat1,
					,null
					,null --'Person'
					,null --4  --NOTICE: Should be replace in by import function
					,'journalnotat'::SagRelationJournalPostSpecifikKode
					, ROW('journal_txt1','journal_notat1','journal_format1')::JournalNotatType --journalNotat
					,ROW(null, ROW(null,null)::OffentlighedundtagetType) ::JournalPostDokumentAttrType --journalDokumentAttr
				) ::sagRelationType
				] ::sagRelationType[]
			)::SagRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_5 @> actual_search_res_5 and actual_search_res_5 @>expected_search_res_5 and coalesce(array_length(expected_search_res_5,1),0)=coalesce(array_length(actual_search_res_5,1),0), 'search sag reltion extra meta data #5.');


/************************************************/
expected_search_res_6:=array[new_uuid1,new_uuid2]::uuid[];

actual_search_res_6:=as_search_sag(null,null,
		ROW(
				null --registrering RegistreringBase,
				,array[] :: SagFremdriftTilsType[]
				,null --attrEgenskaber SagEgenskaberAttrType[],
				,ARRAY[
				ROW (
					'journalpost'::sagRelationKode
					,null--	virkJournalNotat1,
					,null--uuidJournalNotat1,
					,null
					,null --'Person'
					,null --4  --NOTICE: Should be replace in by import function
					,'journalnotat'::SagRelationJournalPostSpecifikKode
					, ROW(null,null,'journal_format2')::JournalNotatType --journalNotat
					,ROW(null, ROW(null,null)::OffentlighedundtagetType) ::JournalPostDokumentAttrType --journalDokumentAttr
				) ::sagRelationType
				] ::sagRelationType[]
			)::SagRegistreringType	
		,null
);

RETURN NEXT ok(expected_search_res_6 @> actual_search_res_6 and actual_search_res_6 @>expected_search_res_6 and coalesce(array_length(expected_search_res_6,1),0)=coalesce(array_length(actual_search_res_6,1),0), 'search sag reltion extra meta data #6.');



END;
$$;