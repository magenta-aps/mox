-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_search_dokument()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 

doc1_new_uuid uuid;
	doc1_registrering dokumentRegistreringType;
	doc1_virkEgenskaber1 Virkning;
	doc1_virkEgenskaber2 Virkning;
	doc1_virkAnsvarlig Virkning;
	doc1_virkBesvarelser1 Virkning;
	doc1_virkBesvarelser2 Virkning;
	doc1_virkFremdrift Virkning;
	doc1_dokumentEgenskab1 dokumentEgenskaberAttrType;
	doc1_dokumentEgenskab2 dokumentEgenskaberAttrType;
	doc1_dokumentFremdrift dokumentFremdriftTilsType;
	doc1_dokumentRelAnsvarlig dokumentRelationType;
	doc1_dokumentRelBesvarelser1 dokumentRelationType;
	doc1_dokumentRelBesvarelser2 dokumentRelationType;
	doc1_uuidAnsvarlig uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	doc1_uuidBesvarelser1 uuid :='b7160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;
	--uuidBesvarelser2 uuid :='08533179-fedb-4aa7-8902-ab34a219eed9'::uuid;
	doc1_urnBesvarelser2 text:='urn:isbn:0451450523'::text;
	doc1_uuidRegistrering uuid :='1f368584-4c3e-4ba4-837b-da2b1eee37c9'::uuid;
	doc1_docVariant1 DokumentVariantType;
	doc1_docVariant2 DokumentVariantType;
	doc1_docVariantEgenskaber1A DokumentVariantEgenskaberType;
	doc1_docVariantEgenskaber1AVirkning Virkning;
	doc1_docVariantEgenskaber1B DokumentVariantEgenskaberType;
	doc1_docVariantEgenskaber1BVirkning Virkning;
	doc1_docVariantEgenskaber2A DokumentVariantEgenskaberType;
	doc1_docVariantEgenskaber2AVirkning Virkning;	
	doc1_docDel1A DokumentDelType;
	doc1_docDel1B DokumentDelType;
	doc1_docDel2A DokumentDelType;
	doc1_docDel2B DokumentDelType;
	doc1_docDel1AEgenskaber DokumentDelEgenskaberType;
	doc1_docDel1A2Egenskaber DokumentDelEgenskaberType;
	doc1_docDel1AEgenskaberVirkning Virkning;
	doc1_docDel1A2EgenskaberVirkning Virkning;
	doc1_docDel1BEgenskaber DokumentDelEgenskaberType;
	doc1_docDel1BEgenskaberVirkning Virkning;
	doc1_docDel2AEgenskaber DokumentDelEgenskaberType;
	doc1_docDel2AEgenskaberVirkning Virkning;
	doc1_docDel1Arelation1 DokumentdelRelationType;
	doc1_docDel1Arelation1Virkning Virkning;
	doc1_docDel2Brelation1 DokumentdelRelationType;
	doc1_docDel2Brelation1Virkning Virkning;
	doc1_docDel2Brelation2 DokumentdelRelationType;
	doc1_docDel2Brelation2Virkning Virkning;

	doc1_extraRel1 DokumentdelRelationType;
	doc1_extraRel2 DokumentdelRelationType;
	doc1_extraRelVirkning1 Virkning;
	doc1_extraRelVirkning2 Virkning;

	doc2_new_uuid uuid;
	doc2_registrering dokumentRegistreringType;
	doc2_virkEgenskaber1 Virkning;
	doc2_virkEgenskaber2 Virkning;
	doc2_virkAnsvarlig Virkning;
	doc2_virkBesvarelser1 Virkning;
	doc2_virkBesvarelser2 Virkning;
	doc2_virkFremdrift Virkning;
	doc2_dokumentEgenskab1 dokumentEgenskaberAttrType;
	doc2_dokumentEgenskab2 dokumentEgenskaberAttrType;
	doc2_dokumentFremdrift dokumentFremdriftTilsType;
	doc2_dokumentRelAnsvarlig dokumentRelationType;
	doc2_dokumentRelBesvarelser1 dokumentRelationType;
	doc2_dokumentRelBesvarelser2 dokumentRelationType;
	doc2_uuidAnsvarlig uuid :='20109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	doc2_uuidBesvarelser1 uuid :='15160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;
	--uuidBesvarelser2 uuid :='08533179-fedb-4aa7-8902-ab34a219eed9'::uuid;
	doc2_urnBesvarelser2 text:='urn:isbn:0451450529'::text;
	doc2_uuidRegistrering uuid :='17368584-4c3e-4ba4-837b-da2b1eee37c9'::uuid;
	doc2_docVariant1 DokumentVariantType;
	doc2_docVariant2 DokumentVariantType;
	doc2_docVariantEgenskaber1A DokumentVariantEgenskaberType;
	doc2_docVariantEgenskaber1AVirkning Virkning;
	doc2_docVariantEgenskaber1B DokumentVariantEgenskaberType;
	doc2_docVariantEgenskaber1BVirkning Virkning;
	doc2_docVariantEgenskaber2A DokumentVariantEgenskaberType;
	doc2_docVariantEgenskaber2AVirkning Virkning;	
	doc2_docDel1A DokumentDelType;
	doc2_docDel1B DokumentDelType;
	doc2_docDel2A DokumentDelType;
	doc2_docDel2B DokumentDelType;
	doc2_docDel1AEgenskaber DokumentDelEgenskaberType;
	doc2_docDel1A2Egenskaber DokumentDelEgenskaberType;
	doc2_docDel1AEgenskaberVirkning Virkning;
	doc2_docDel1A2EgenskaberVirkning Virkning;
	doc2_docDel1BEgenskaber DokumentDelEgenskaberType;
	doc2_docDel1BEgenskaberVirkning Virkning;
	doc2_docDel2AEgenskaber DokumentDelEgenskaberType;
	doc2_docDel2AEgenskaberVirkning Virkning;
	doc2_docDel1Arelation1 DokumentdelRelationType;
	doc2_docDel1Arelation1Virkning Virkning;
	doc2_docDel2Brelation1 DokumentdelRelationType;
	doc2_docDel2Brelation1Virkning Virkning;
	doc2_docDel2Brelation2 DokumentdelRelationType;
	doc2_docDel2Brelation2Virkning Virkning;

	doc2_extraRel1 DokumentdelRelationType;
	doc2_extraRel2 DokumentdelRelationType;
	doc2_extraRelVirkning1 Virkning;
	doc2_extraRelVirkning2 Virkning;


doc3_new_uuid uuid;
	doc3_registrering dokumentRegistreringType;
	doc3_virkEgenskaber1 Virkning;
	doc3_virkEgenskaber2 Virkning;
	doc3_virkAnsvarlig Virkning;
	doc3_virkBesvarelser1 Virkning;
	doc3_virkBesvarelser2 Virkning;
	doc3_virkFremdrift Virkning;
	doc3_dokumentEgenskab1 dokumentEgenskaberAttrType;
	doc3_dokumentEgenskab2 dokumentEgenskaberAttrType;
	doc3_dokumentFremdrift dokumentFremdriftTilsType;
	doc3_dokumentRelAnsvarlig dokumentRelationType;
	doc3_dokumentRelBesvarelser1 dokumentRelationType;
	doc3_dokumentRelBesvarelser2 dokumentRelationType;
	doc3_uuidAnsvarlig uuid :='85109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	doc3_uuidBesvarelser1 uuid :='56160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;
	--uuidBesvarelser2 uuid :='08533179-fedb-4aa7-8902-ab34a219eed9'::uuid;
	doc3_urnBesvarelser2 text:='urn:isbn:2451450529'::text;
	doc3_uuidRegistrering uuid :='84368584-4c3e-4ba4-837b-da2b1eee37c9'::uuid;
	doc3_docVariant1 DokumentVariantType;
	doc3_docVariant2 DokumentVariantType;
	doc3_docVariantEgenskaber1A DokumentVariantEgenskaberType;
	doc3_docVariantEgenskaber1AVirkning Virkning;
	doc3_docVariantEgenskaber1B DokumentVariantEgenskaberType;
	doc3_docVariantEgenskaber1BVirkning Virkning;
	doc3_docVariantEgenskaber2A DokumentVariantEgenskaberType;
	doc3_docVariantEgenskaber2AVirkning Virkning;	
	doc3_docDel1A DokumentDelType;
	doc3_docDel1B DokumentDelType;
	doc3_docDel2A DokumentDelType;
	doc3_docDel2B DokumentDelType;
	doc3_docDel1AEgenskaber DokumentDelEgenskaberType;
	doc3_docDel1A2Egenskaber DokumentDelEgenskaberType;
	doc3_docDel1AEgenskaberVirkning Virkning;
	doc3_docDel1A2EgenskaberVirkning Virkning;
	doc3_docDel1BEgenskaber DokumentDelEgenskaberType;
	doc3_docDel1BEgenskaberVirkning Virkning;
	doc3_docDel2AEgenskaber DokumentDelEgenskaberType;
	doc3_docDel2AEgenskaberVirkning Virkning;
	doc3_docDel1Arelation1 DokumentdelRelationType;
	doc3_docDel1Arelation1Virkning Virkning;
	doc3_docDel2Brelation1 DokumentdelRelationType;
	doc3_docDel2Brelation1Virkning Virkning;
	doc3_docDel2Brelation2 DokumentdelRelationType;
	doc3_docDel2Brelation2Virkning Virkning;

	doc3_extraRel1 DokumentdelRelationType;
	doc3_extraRel2 DokumentdelRelationType;
	doc3_extraRelVirkning1 Virkning;
	doc3_extraRelVirkning2 Virkning;


	search_result1 uuid[];
	search_result2 uuid[];
	search_result3 uuid[];
	search_result4 uuid[];
	search_result5 uuid[];
	search_result6 uuid[];
	search_result7 uuid[];
	search_result8 uuid[];
	search_result9 uuid[];

	expected_result1 uuid[];
	expected_result2 uuid[];
	expected_result3 uuid[];
	expected_result4 uuid[];
	expected_result5 uuid[];
	expected_result6 uuid[];
	expected_result7 uuid[];
	expected_result8 uuid[];
	expected_result9 uuid[];
	
	read_doc1 DokumentType;
	read_doc2 DokumentType;
	read_doc3 DokumentType;

	search_reg11 DokumentRegistreringType;
	search_reg12 DokumentRegistreringType;
	search_reg13 DokumentRegistreringType;
	search_reg14 DokumentRegistreringType;
	search_reg15 DokumentRegistreringType;
	search_reg16 DokumentRegistreringType;
	search_reg17 DokumentRegistreringType;
	search_reg18 DokumentRegistreringType;
	search_reg19 DokumentRegistreringType;


	search_result11 uuid[];
	search_result12 uuid[];
	search_result13 uuid[];
	search_result14 uuid[];
	search_result15 uuid[];
	search_result16 uuid[];
	search_result17 uuid[];
	search_result18 uuid[];
	search_result19 uuid[];

	expected_result11 uuid[];
	expected_result12 uuid[];
	expected_result13 uuid[];
	expected_result14 uuid[];
	expected_result15 uuid[];
	expected_result16 uuid[];
	expected_result17 uuid[];
	expected_result18 uuid[];
	expected_result19 uuid[];
	

	search_reg21 DokumentRegistreringType;
	search_reg22 DokumentRegistreringType;
	search_reg23 DokumentRegistreringType;
	search_reg24 DokumentRegistreringType;
	search_reg25 DokumentRegistreringType;
	search_reg26 DokumentRegistreringType;
	search_reg27 DokumentRegistreringType;
	search_reg28 DokumentRegistreringType;
	search_reg29 DokumentRegistreringType;
	search_reg20 DokumentRegistreringType;

	search_result20 uuid[];
	search_result21 uuid[];
	search_result22 uuid[];
	search_result23 uuid[];
	search_result24 uuid[];
	search_result25 uuid[];
	search_result26 uuid[];
	search_result27 uuid[];
	search_result28 uuid[];
	search_result29 uuid[];

	expected_result20 uuid[];
	expected_result21 uuid[];
	expected_result22 uuid[];
	expected_result23 uuid[];
	expected_result24 uuid[];
	expected_result25 uuid[];
	expected_result26 uuid[];
	expected_result27 uuid[];
	expected_result28 uuid[];
	expected_result29 uuid[];

	search_result30 uuid[];
	search_result31 uuid[];
	search_result32 uuid[];
	search_result33 uuid[];
	search_result34 uuid[];
	search_result35 uuid[];
	search_result36 uuid[];
	search_result37 uuid[];
	search_result38 uuid[];
	search_result39 uuid[];

	expected_result30 uuid[];
	expected_result31 uuid[];
	expected_result32 uuid[];
	expected_result33 uuid[];
	expected_result34 uuid[];
	expected_result35 uuid[];
	expected_result36 uuid[];
	expected_result37 uuid[];
	expected_result38 uuid[];
	expected_result39 uuid[];



BEGIN 

doc1_virkEgenskaber1 :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          'd71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;


doc1_virkEgenskaber2 :=	ROW (
	'[2014-05-12, 2015-05-12)' :: TSTZRANGE,
          'e71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx11'
          ) :: Virkning
;


doc1_virkAnsvarlig :=	ROW (
	'[2014-05-11, infinity)' :: TSTZRANGE,
          'f71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

doc1_virkBesvarelser1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          'c71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


doc1_virkBesvarelser2 :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          'b71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;

doc1_virkFremdrift := ROW (
	'[2015-05-18, infinity)' :: TSTZRANGE,
          'a71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx10'
) :: Virkning
;

doc1_dokumentRelAnsvarlig := ROW (
	'ansvarlig'::dokumentRelationKode,
		doc1_virkAnsvarlig,
	doc1_uuidAnsvarlig,
	null,
	'Aktør'
) :: dokumentRelationType
;


doc1_dokumentRelBesvarelser1 := ROW (
	'besvarelser'::dokumentRelationKode,
		doc1_virkBesvarelser1,
	doc1_uuidBesvarelser1,
	null,
	null
) :: dokumentRelationType
;



doc1_dokumentRelBesvarelser2 := ROW (
	'besvarelser'::dokumentRelationKode,
		doc1_virkBesvarelser2,
	null,
	doc1_urnBesvarelser2,
	null
) :: dokumentRelationType
;


doc1_dokumentFremdrift := ROW (
doc1_virkFremdrift,
'Underreview'
):: dokumentFremdriftTilsType
;


doc1_dokumentEgenskab1 := ROW (
'doc_brugervendtnoegle1',
'doc_beskrivelse1', 
'2015-10-31'::date,
'doc_kassationskode1', 
4, --major int
9, --minor int
ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
'doc_titel1',
'doc_dokumenttype1',
'integrationsdata1',
   doc1_virkEgenskaber1
) :: dokumentEgenskaberAttrType
;

doc1_dokumentEgenskab2 := ROW (
'doc_brugervendtnoegle2',
'doc_beskrivelse2', 
'2014-09-20'::date,
'doc_kassationskode2', 
5, --major int
10, --minor int
ROW('doc_Offentlighedundtaget_AlternativTitel2','doc_Offentlighedundtaget_Hjemmel2') ::OffentlighedundtagetType, --offentlighedundtagettype,
'doc_titel2',
'doc_dokumenttype2',
'integrationsdata2',
   doc1_virkEgenskaber2
) :: dokumentEgenskaberAttrType
;




doc1_docDel2Brelation2Virkning :=	ROW (
	'(2014-02-24, 2015-10-01]' :: TSTZRANGE,
          '971cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx70'
          ) :: Virkning
;

doc1_docDel2Brelation1Virkning :=	ROW (
	'[2012-05-08, infinity)' :: TSTZRANGE,
          '871cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx70'
          ) :: Virkning
;


doc1_docDel1Arelation1Virkning :=	ROW (
	'[2015-05-09, infinity)' :: TSTZRANGE,
          '771cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx71'
          ) :: Virkning
;


doc1_docVariantEgenskaber2AVirkning :=	ROW (
	'[2014-07-12, infinity)' :: TSTZRANGE,
          '671cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx281'
          ) :: Virkning
;

doc1_docVariantEgenskaber1BVirkning :=	ROW (
	'[2015-01-01, infinity)' :: TSTZRANGE,
          '571cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx291'
          ) :: Virkning
;


doc1_docVariantEgenskaber1AVirkning :=	ROW (
	'[2013-02-27, 2015-01-01)' :: TSTZRANGE,
          '471cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx191'
          ) :: Virkning
;

doc1_docDel1AEgenskaberVirkning :=	ROW (
	'[2014-03-30, infinity)' :: TSTZRANGE,
          '371cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx11'
          ) :: Virkning
;

doc1_docDel1A2EgenskaberVirkning :=	ROW (
	'[2010-01-20, 2014-03-20)' :: TSTZRANGE,
          '271cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx113'
          ) :: Virkning
;


doc1_docDel1BEgenskaberVirkning :=	ROW (
	'[2015-10-11, infinity)' :: TSTZRANGE,
          '171cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx12'
          ) :: Virkning
;

doc1_docDel2AEgenskaberVirkning :=	ROW (
	'[2013-02-28, infinity)' :: TSTZRANGE,
          '901cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx13'
          ) :: Virkning
;

doc1_extraRelVirkning1 :=	ROW (
	'[2013-02-28, infinity)' :: TSTZRANGE,
          '120cc58a-3149-414a-9392-dcbcbbccddd9'::uuid,
          'Bruger',
          'NoteEx23'
          ) :: Virkning
;
doc1_extraRelVirkning2 :=	ROW (
	'[2013-02-28, infinity)' :: TSTZRANGE,
          '280cc58a-3149-414a-9392-dcbcbbccddc0'::uuid,
          'Bruger',
          'NoteEx143'
          ) :: Virkning
;


doc1_docVariantEgenskaber1A:=
ROW(
true, --arkivering boolean, 
false, --delvisscannet boolean, 
true, --offentliggoerelse boolean, 
false, --produktion boolean,
 doc1_docVariantEgenskaber1AVirkning
)::DokumentVariantEgenskaberType;

doc1_docVariantEgenskaber1B:=
ROW(
false, --arkivering boolean, 
false, --delvisscannet boolean, 
true, --offentliggoerelse boolean, 
true, --produktion boolean,
 doc1_docVariantEgenskaber1BVirkning
)::DokumentVariantEgenskaberType;


doc1_docVariantEgenskaber2A:=
ROW(
false, --arkivering boolean, 
true, --delvisscannet boolean, 
false, --offentliggoerelse boolean, 
true, --produktion boolean,
 doc1_docVariantEgenskaber2AVirkning
)::DokumentVariantEgenskaberType;


doc1_docDel2Brelation1:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc1_docDel2Brelation1Virkning,
  'a24a2dd4-415f-4104-b7a7-84607488c096'::uuid,
  null, --urn,
  'Bruger'
)::DokumentdelRelationType;


doc1_docDel2Brelation2:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc1_docDel2Brelation2Virkning,
  null,
  'urn:cpr 8883394', 
  'Bruger'
)::DokumentdelRelationType;


doc1_docDel1Arelation1:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc1_docDel1Arelation1Virkning,
  'b24a2dd4-415f-4104-b7a7-84607488c091'::uuid,
  null, 
  'Bruger'
)::DokumentdelRelationType;

doc1_extraRel1:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc1_extraRelVirkning1,
  '009a2dd4-415f-4104-b7a7-84607488c027'::uuid,
  null, 
  'Bruger'
)::DokumentdelRelationType;


doc1_extraRel2:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc1_extraRelVirkning2,
  '889a2dd4-415f-4104-b7a7-84607488c019'::uuid,
  null, 
  'Bruger'
)::DokumentdelRelationType;



doc1_docDel1AEgenskaber:= ROW(
1, --indeks int,
'del_indhold1', 
'del_lokation1', 
'del_mimetype1',
 doc1_docDel1AEgenskaberVirkning 
)::DokumentDelEgenskaberType
;

doc1_docDel1A2Egenskaber:=ROW(
2, --indeks int,
'del_indhold4', 
'del_lokation4', 
'del_mimetype4',
 doc1_docDel1A2EgenskaberVirkning 
)::DokumentDelEgenskaberType
;

doc1_docDel1BEgenskaber:= ROW(
98, --indeks int,
'del_indhold2', 
'del_lokation2', 
'del_mimetype2',
 doc1_docDel1BEgenskaberVirkning 
)::DokumentDelEgenskaberType
;

doc1_docDel2AEgenskaber:= ROW(
8, --indeks int,
'del_indhold3', 
'del_lokation3', 
'del_mimetype3',
 doc1_docDel2AEgenskaberVirkning 
)::DokumentDelEgenskaberType
;


doc1_docDel1A:=
ROW(
'doc_deltekst1A',
  ARRAY[doc1_docDel1AEgenskaber,doc1_docDel1A2Egenskaber],
  ARRAY[doc1_docDel1Arelation1]
)::DokumentDelType;

doc1_docDel1B:=
ROW(
'doc_deltekst1B',
  ARRAY[doc1_docDel1BEgenskaber],
  null--ARRAY[]::DokumentdelRelationType[]
)::DokumentDelType;

doc1_docDel2A:=
ROW(
'doc_deltekst2A',
  ARRAY[doc1_docDel2AEgenskaber],
  null--ARRAY[]::DokumentdelRelationType[]
)::DokumentDelType;

doc1_docDel2B:=
ROW(
'doc_deltekst2B',
  null,--ARRAY[]::DokumentDelEgenskaberType[],
  ARRAY[doc1_docDel2Brelation1,doc1_docDel2Brelation2]
)::DokumentDelType;


doc1_docVariant1 := ROW (
	'doc_varianttekst2_1',
  	ARRAY[doc1_docVariantEgenskaber1B,doc1_docVariantEgenskaber1A],
  	ARRAY[doc1_docDel1A,
  	ROW(
  		'doc_deltekst1B',
  		ARRAY[doc1_docDel1BEgenskaber],
  		ARRAY[doc1_extraRel1,doc1_extraRel2]
  		)::DokumentDelType
  	]
)::DokumentVariantType;


doc1_docVariant2 := ROW (
	'doc_varianttekst2',
  ARRAY[doc1_docVariantEgenskaber2A],
  ARRAY[doc1_docDel2A,doc1_docDel2B]
)::DokumentVariantType;

doc1_registrering := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	doc1_uuidRegistrering,
	'Test Note 85') :: RegistreringBase
	,
ARRAY[doc1_dokumentFremdrift]::dokumentFremdriftTilsType[],
ARRAY[doc1_dokumentEgenskab1,doc1_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
ARRAY[doc1_dokumentRelBesvarelser1,doc1_dokumentRelAnsvarlig,doc1_dokumentRelBesvarelser2],
ARRAY[doc1_docVariant1,doc1_docVariant2]
) :: dokumentRegistreringType
;


doc1_new_uuid := as_create_or_import_dokument(doc1_registrering);



/***************************************************/
/*
firstResult int,--TOOD ??
	klasse_uuid uuid,
	registreringObj KlasseRegistreringType,
	virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
*/


search_result1 :=as_search_dokument(
	null,--TOOD ??
	null,
	ROW(
		null, --registrering
		null, --fremdrift
		ARRAY[
		ROW(
			NULL--'doc_brugervendtnoegle1',
			,NULL--'doc_beskrivelse1', 
			,'2015-10-31'::date
			,NULL --'doc_kassationskode1', 
			,NULL --4, --major int
			,NULL --9, --minor int
			,NULL --ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
			,NULL --'doc_titel1',
			,NULL --'doc_dokumenttype1',
			,NULL --'integrationsdata1',
	   		,null
		) :: dokumentEgenskaberAttrType
		], --egenskaber
		null, --relationer
		null --varianter
	)::dokumentRegistreringType
	,null
	);

expected_result1=array[doc1_new_uuid]::uuid[];

RETURN NEXT is(search_result1, expected_result1 ,'test dokument search.#1');


/***************************************************/




search_result2 :=as_search_dokument(
	null,--TOOD ??
	null,
	ROW(
		null, --registrering
		null, --fremdrift
		ARRAY[
		ROW(
			NULL--'doc_brugervendtnoegle1',
			,NULL--'doc_beskrivelse1', 
			,'2015-10-30'::date
			,NULL --'doc_kassationskode1', 
			,NULL --4, --major int
			,NULL --9, --minor int
			,NULL --ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
			,NULL --'doc_titel1',
			,NULL --'doc_dokumenttype1',
			,NULL --'integrationsdata1',
	   		,null
		) :: dokumentEgenskaberAttrType
		], --egenskaber
		null, --relationer
		null --varianter
	)::dokumentRegistreringType
	,null
	);

expected_result2=array[]::uuid[];

RETURN NEXT is(search_result2, expected_result2 ,'test dokument search.#2');

/***************************************************/


search_result3 :=as_search_dokument(
	null,--TOOD ??
	null,
	ROW(
		null, --registrering
		null, --fremdrift
		ARRAY[
		ROW(
			NULL--'doc_brugervendtnoegle1',
			,NULL--'doc_beskrivelse1', 
			,NULL
			,NULL --'doc_kassationskode1', 
			,4 --NULL --4, --major int
			,NULL --9, --minor int
			,NULL --ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
			,NULL --'doc_titel1',
			,NULL --'doc_dokumenttype1',
			,NULL --'integrationsdata1',
	   		,null
		) :: dokumentEgenskaberAttrType
		], --egenskaber
		null, --relationer
		null --varianter
	)::dokumentRegistreringType
	,null
	);

expected_result3=array[doc1_new_uuid]::uuid[];

RETURN NEXT is(search_result3, expected_result3 ,'test dokument search.#3');

/***************************************************/


search_result4 :=as_search_dokument(
	null,--TOOD ??
	null,
	ROW(
		null, --registrering
		null, --fremdrift
		ARRAY[
		ROW(
			NULL--'doc_brugervendtnoegle1',
			,NULL--'doc_beskrivelse1', 
			,NULL
			,NULL --'doc_kassationskode1', 
			,6 --NULL --4, --major int
			,NULL --9, --minor int
			,NULL --ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
			,NULL --'doc_titel1',
			,NULL --'doc_dokumenttype1',
			,NULL --'integrationsdata1',
	   		,null
		) :: dokumentEgenskaberAttrType
		], --egenskaber
		null, --relationer
		null --varianter
	)::dokumentRegistreringType
	,null
	);

expected_result4=array[]::uuid[];

RETURN NEXT is(search_result4, expected_result4 ,'test dokument search.#4');


/***************************************************/


search_result5 :=as_search_dokument(
	null,--TOOD ??
	null,
	ROW(
		null, --registrering
		null, --fremdrift
		ARRAY[
		ROW(
			NULL--'doc_brugervendtnoegle1',
			,NULL--'doc_beskrivelse1', 
			,NULL
			,NULL --'doc_kassationskode1', 
			,NULL  --4, --major int
			,NULL --9, --minor int
			,ROW('doc_Offentlighedundtaget_AlternativTitel3',null) --ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
			,NULL --'doc_titel1',
			,NULL --'doc_dokumenttype1',
			,NULL --'integrationsdata1',
	   		,null
		) :: dokumentEgenskaberAttrType
		], --egenskaber
		null, --relationer
		null --varianter
	)::dokumentRegistreringType
	,null
	);

expected_result5=array[]::uuid[];

RETURN NEXT is(search_result5, expected_result5 ,'test dokument search.#5');


/***************************************************/


search_result6 :=as_search_dokument(
	null,--TOOD ??
	null,
	ROW(
		null, --registrering
		null, --fremdrift
		ARRAY[
		ROW(
			NULL--'doc_brugervendtnoegle1',
			,NULL--'doc_beskrivelse1', 
			,NULL
			,NULL --'doc_kassationskode1', 
			,NULL  --4, --major int
			,NULL --9, --minor int
			,ROW('doc_Offentlighedundtaget_AlternativTitel2',null) --ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
			,NULL --'doc_titel1',
			,NULL --'doc_dokumenttype1',
			,NULL --'integrationsdata1',
	   		,null
		) :: dokumentEgenskaberAttrType
		], --egenskaber
		null, --relationer
		null --varianter
	)::dokumentRegistreringType
	,null
	);

expected_result6=array[doc1_new_uuid]::uuid[];

RETURN NEXT is(search_result6, expected_result6 ,'test dokument search.#6');

/***************************************************/


search_result7 :=as_search_dokument(
	null,--TOOD ??
	null,
	ROW(
		null, --registrering
		null, --fremdrift
		ARRAY[
		ROW(
			NULL--'doc_brugervendtnoegle1',
			,NULL--'doc_beskrivelse1', 
			,NULL
			,NULL --'doc_kassationskode1', 
			,NULL  --4, --major int
			,NULL --9, --minor int
			,ROW('doc_Offentlighedundtaget_AlternativTitel2','doc_Offentlighedundtaget_Hjemmel1') --ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
			,NULL --'doc_titel1',
			,NULL --'doc_dokumenttype1',
			,NULL --'integrationsdata1',
	   		,null
		) :: dokumentEgenskaberAttrType
		], --egenskaber
		null, --relationer
		null --varianter
	)::dokumentRegistreringType
	,null
	);

expected_result7=array[]::uuid[];

RETURN NEXT is(search_result7, expected_result7 ,'test dokument search.#7');


/***************************************************/


search_result8 :=as_search_dokument(
	null,--TOOD ??
	null,
	ROW(
		null, --registrering
		null, --fremdrift
		ARRAY[
		ROW(
			NULL--'doc_brugervendtnoegle1',
			,NULL--'doc_beskrivelse1', 
			,NULL
			,NULL --'doc_kassationskode1', 
			,NULL  --4, --major int
			,NULL --9, --minor int
			,ROW(null,'doc_Offentlighedundtaget_Hjemmel2') --ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
			,NULL --'doc_titel1',
			,NULL --'doc_dokumenttype1',
			,NULL --'integrationsdata1',
	   		,null
		) :: dokumentEgenskaberAttrType
		], --egenskaber
		null, --relationer
		null --varianter
	)::dokumentRegistreringType
	,null
	);

expected_result8=array[doc1_new_uuid]::uuid[];

RETURN NEXT is(search_result8, expected_result8 ,'test dokument search.#8');



/***************************************************/


search_result9 :=as_search_dokument(
	null,--TOOD ??
	null,
	ROW(
		null, --registrering
		null, --fremdrift
		ARRAY[
		ROW(
			NULL--'doc_brugervendtnoegle1',
			,NULL--'doc_beskrivelse1', 
			,NULL
			,NULL --'doc_kassationskode1', 
			,NULL  --4, --major int
			,NULL --9, --minor int
			,ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType --offentlighedundtagettype,
			,NULL --'doc_titel1',
			,NULL --'doc_dokumenttype1',
			,NULL --'integrationsdata1',
	   		,null
		) :: dokumentEgenskaberAttrType
		], --egenskaber
		null, --relationer
		null --varianter
	)::dokumentRegistreringType
	,null
	);

expected_result9=array[doc1_new_uuid]::uuid[];

RETURN NEXT is(search_result9, expected_result9 ,'test dokument search.#9');



/***************************************************/


doc2_virkEgenskaber1 :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          'd71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;


doc2_virkEgenskaber2 :=	ROW (
	'[2014-05-12, 2015-05-12)' :: TSTZRANGE,
          'e71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx11'
          ) :: Virkning
;


doc2_virkAnsvarlig :=	ROW (
	'[2013-05-11, infinity)' :: TSTZRANGE,
          'f71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

doc2_virkBesvarelser1 :=	ROW (
	'[2014-05-10, infinity)' :: TSTZRANGE,
          'c71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


doc2_virkBesvarelser2 :=	ROW (
	'[2014-05-10, 2016-05-10)' :: TSTZRANGE,
          'b71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;

doc2_virkFremdrift := ROW (
	'[2014-05-18, infinity)' :: TSTZRANGE,
          'a71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx10'
) :: Virkning
;

doc2_dokumentRelAnsvarlig := ROW (
	'ansvarlig'::dokumentRelationKode,
		doc2_virkAnsvarlig,
	doc2_uuidAnsvarlig,
	null,
	'Aktør'
) :: dokumentRelationType
;


doc2_dokumentRelBesvarelser1 := ROW (
	'besvarelser'::dokumentRelationKode,
		doc2_virkBesvarelser1,
	doc2_uuidBesvarelser1,
	null,
	null
) :: dokumentRelationType
;



doc2_dokumentRelBesvarelser2 := ROW (
	'besvarelser'::dokumentRelationKode,
		doc2_virkBesvarelser2,
	null,
	doc2_urnBesvarelser2,
	null
) :: dokumentRelationType
;


doc2_dokumentFremdrift := ROW (
doc2_virkFremdrift,
'Underreview'
):: dokumentFremdriftTilsType
;


doc2_dokumentEgenskab1 := ROW (
'doc2_brugervendtnoegle1',
'doc_beskrivelse1', 
'2015-09-30'::date,
'doc2_kassationskode1', 
3, --major int
34, --minor int
ROW('doc2_Offentlighedundtaget_AlternativTitel1','doc2_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
'doc2_titel1',
'doc2_dokumenttype1',
'integrationsdata1',
   doc2_virkEgenskaber1
) :: dokumentEgenskaberAttrType
;

doc2_dokumentEgenskab2 := ROW (
'doc2_brugervendtnoegle2',
'doc_beskrivelse1', 
'2014-08-20'::date,
'doc2_kassationskode2', 
8, --major int
12, --minor int
ROW('doc2_Offentlighedundtaget_AlternativTitel2','doc2_Offentlighedundtaget_Hjemmel2') ::OffentlighedundtagetType, --offentlighedundtagettype,
'doc2_titel2',
'doc2_dokumenttype2',
'integrationsdata2',
   doc2_virkEgenskaber2
) :: dokumentEgenskaberAttrType
;




doc2_docDel2Brelation2Virkning :=	ROW (
	'(2014-02-24, 2015-10-01]' :: TSTZRANGE,
          '971cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx70'
          ) :: Virkning
;

doc2_docDel2Brelation1Virkning :=	ROW (
	'[2012-05-08, infinity)' :: TSTZRANGE,
          '871cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx70'
          ) :: Virkning
;


doc2_docDel1Arelation1Virkning :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          '771cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx71'
          ) :: Virkning
;


doc2_docVariantEgenskaber2AVirkning :=	ROW (
	'[2014-07-12, infinity)' :: TSTZRANGE,
          '671cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx281'
          ) :: Virkning
;

doc2_docVariantEgenskaber1BVirkning :=	ROW (
	'[2015-01-01, infinity)' :: TSTZRANGE,
          '571cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx291'
          ) :: Virkning
;


doc2_docVariantEgenskaber1AVirkning :=	ROW (
	'[2010-02-27, 2015-01-01)' :: TSTZRANGE,
          '471cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx191'
          ) :: Virkning
;

doc2_docDel1AEgenskaberVirkning :=	ROW (
	'[2014-03-28, infinity)' :: TSTZRANGE,
          '371cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx11'
          ) :: Virkning
;

doc2_docDel1A2EgenskaberVirkning :=	ROW (
	'[2010-01-20, 2014-03-20)' :: TSTZRANGE,
          '271cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx113'
          ) :: Virkning
;


doc2_docDel1BEgenskaberVirkning :=	ROW (
	'[2015-10-11, infinity)' :: TSTZRANGE,
          '171cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx12'
          ) :: Virkning
;

doc2_docDel2AEgenskaberVirkning :=	ROW (
	'[2013-02-28, infinity)' :: TSTZRANGE,
          '901cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx13'
          ) :: Virkning
;

doc2_extraRelVirkning1 :=	ROW (
	'[2013-02-28, infinity)' :: TSTZRANGE,
          '120cc58a-3149-414a-9392-dcbcbbccddd9'::uuid,
          'Bruger',
          'NoteEx23'
          ) :: Virkning
;
doc2_extraRelVirkning2 :=	ROW (
	'[2013-02-28, infinity)' :: TSTZRANGE,
          '280cc58a-3149-414a-9392-dcbcbbccddc0'::uuid,
          'Bruger',
          'NoteEx143'
          ) :: Virkning
;


doc2_docVariantEgenskaber1A:=
ROW(
false, --arkivering boolean, 
true, --delvisscannet boolean, 
true, --offentliggoerelse boolean, 
false, --produktion boolean,
 doc2_docVariantEgenskaber1AVirkning
)::DokumentVariantEgenskaberType;

doc2_docVariantEgenskaber1B:=
ROW(
false, --arkivering boolean, 
true, --delvisscannet boolean, 
true, --offentliggoerelse boolean, 
true, --produktion boolean,
 doc2_docVariantEgenskaber1BVirkning
)::DokumentVariantEgenskaberType;


doc2_docVariantEgenskaber2A:=
ROW(
true, --arkivering boolean, 
true, --delvisscannet boolean, 
false, --offentliggoerelse boolean, 
false, --produktion boolean,
 doc2_docVariantEgenskaber2AVirkning
)::DokumentVariantEgenskaberType;


doc2_docDel2Brelation1:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc2_docDel2Brelation1Virkning,
  '904a2dd4-415f-4104-b7a7-84607488c096'::uuid,
  null, --urn,
  'Bruger'
)::DokumentdelRelationType;


doc2_docDel2Brelation2:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc2_docDel2Brelation2Virkning,
  null,
  'urn:cpr 9900000', 
  'Bruger'
)::DokumentdelRelationType;


doc2_docDel1Arelation1:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc2_docDel1Arelation1Virkning,
  '100a2dd4-415f-4104-b7a7-84607488c091'::uuid,
  null, 
  'Bruger'
)::DokumentdelRelationType;

doc2_extraRel1:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc2_extraRelVirkning1,
  '200a2dd4-415f-4104-b7a7-84607488c027'::uuid,
  null, 
  'Bruger'
)::DokumentdelRelationType;


doc2_extraRel2:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc2_extraRelVirkning2,
  '300a2dd4-415f-4104-b7a7-84607488c019'::uuid,
  null, 
  'Bruger'
)::DokumentdelRelationType;



doc2_docDel1AEgenskaber:= ROW(
1, --indeks int,
'del_indhold1_doc2', 
'del_lokation1_doc2', 
'del_mimetype1_doc2',
 doc2_docDel1AEgenskaberVirkning 
)::DokumentDelEgenskaberType
;

doc2_docDel1A2Egenskaber:=ROW(
2, --indeks int,
'del_indhold4_doc2', 
'del_lokation4_doc2', 
'del_mimetype1',
 doc2_docDel1A2EgenskaberVirkning 
)::DokumentDelEgenskaberType
;

doc2_docDel1BEgenskaber:= ROW(
98, --indeks int,
'del_indhold2_doc2', 
'del_lokation2_doc2', 
'del_mimetype2_doc2',
 doc2_docDel1BEgenskaberVirkning 
)::DokumentDelEgenskaberType
;

doc2_docDel2AEgenskaber:= ROW(
8, --indeks int,
'del_indhold3_doc2', 
'del_lokation3_doc2', 
'del_mimetype3_doc2',
 doc2_docDel2AEgenskaberVirkning 
)::DokumentDelEgenskaberType
;


doc2_docDel1A:=
ROW(
'doc2_deltekst1A_doc2',
  ARRAY[doc2_docDel1AEgenskaber,doc2_docDel1A2Egenskaber],
  ARRAY[doc2_docDel1Arelation1]
)::DokumentDelType;

doc2_docDel1B:=
ROW(
'doc2_deltekst1B_doc2',
  ARRAY[doc2_docDel1BEgenskaber],
  null--ARRAY[]::DokumentdelRelationType[]
)::DokumentDelType;

doc2_docDel2A:=
ROW(
'doc2_deltekst2A_doc2',
  ARRAY[doc2_docDel2AEgenskaber],
  null--ARRAY[]::DokumentdelRelationType[]
)::DokumentDelType;

doc2_docDel2B:=
ROW(
'doc2_deltekst2B_doc2',
  null,--ARRAY[]::DokumentDelEgenskaberType[],
  ARRAY[doc2_docDel2Brelation1,doc2_docDel2Brelation2]
)::DokumentDelType;


doc2_docVariant1 := ROW (
	'doc2_varianttekst2_1',
  	ARRAY[doc2_docVariantEgenskaber1B,doc2_docVariantEgenskaber1A],
  	ARRAY[doc2_docDel1A,
  	ROW(
  		'doc2_deltekst1B_doc2',
  		ARRAY[doc2_docDel1BEgenskaber],
  		ARRAY[doc2_extraRel1,doc2_extraRel2]
  		)::DokumentDelType
  	]
)::DokumentVariantType;


doc2_docVariant2 := ROW (
	'doc2_varianttekst2_doc2',
  ARRAY[doc2_docVariantEgenskaber2A],
  ARRAY[doc2_docDel2A,doc2_docDel2B]
)::DokumentVariantType;

doc2_registrering := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	doc2_uuidRegistrering,
	'Test Note 100') :: RegistreringBase
	,
ARRAY[doc2_dokumentFremdrift]::dokumentFremdriftTilsType[],
ARRAY[doc2_dokumentEgenskab1,doc2_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
ARRAY[doc2_dokumentRelBesvarelser1,doc2_dokumentRelAnsvarlig,doc2_dokumentRelBesvarelser2],
ARRAY[doc2_docVariant1,doc2_docVariant2]
) :: dokumentRegistreringType
;


doc2_new_uuid := as_create_or_import_dokument(doc2_registrering);

/***************************************************/

doc3_virkEgenskaber1 :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          'd71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;


doc3_virkEgenskaber2 :=	ROW (
	'[2013-05-12, 2015-05-12)' :: TSTZRANGE,
          'e71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx11'
          ) :: Virkning
;


doc3_virkAnsvarlig :=	ROW (
	'[2013-05-11, infinity)' :: TSTZRANGE,
          'f71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

doc3_virkBesvarelser1 :=	ROW (
	'[2013-05-10, infinity)' :: TSTZRANGE,
          'c71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


doc3_virkBesvarelser2 :=	ROW (
	'[2013-05-10, 2016-05-10)' :: TSTZRANGE,
          'b71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;

doc3_virkFremdrift := ROW (
	'[2013-05-18, infinity)' :: TSTZRANGE,
          'a71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx10'
) :: Virkning
;

doc3_dokumentRelAnsvarlig := ROW (
	'ansvarlig'::dokumentRelationKode,
		doc3_virkAnsvarlig,
	doc3_uuidAnsvarlig,
	null,
	'Aktør'
) :: dokumentRelationType
;


doc3_dokumentRelBesvarelser1 := ROW (
	'besvarelser'::dokumentRelationKode,
		doc3_virkBesvarelser1,
	doc3_uuidBesvarelser1,
	null,
	null
) :: dokumentRelationType
;



doc3_dokumentRelBesvarelser2 := ROW (
	'besvarelser'::dokumentRelationKode,
		doc3_virkBesvarelser2,
	null,
	doc3_urnBesvarelser2,
	null
) :: dokumentRelationType
;


doc3_dokumentFremdrift := ROW (
doc3_virkFremdrift,
'Underreview'
):: dokumentFremdriftTilsType
;


doc3_dokumentEgenskab1 := ROW (
'doc_brugervendtnoegle1_doc3',
'doc_beskrivelse1', 
'2015-10-31'::date,
'doc_kassationskode1_doc3', 
4, --major int
9, --minor int
ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
'doc_titel1',
'doc_dokumenttype1',
'integrationsdata1',
   doc3_virkEgenskaber1
) :: dokumentEgenskaberAttrType
;

doc3_dokumentEgenskab2 := ROW (
'doc_brugervendtnoegle2_doc3',
'doc_beskrivelse1', 
'2014-09-20'::date,
'doc_kassationskode2_doc3', 
5, --major int
10, --minor int
ROW('doc_Offentlighedundtaget_AlternativTitel2','doc_Offentlighedundtaget_Hjemmel2') ::OffentlighedundtagetType, --offentlighedundtagettype,
'doc_titel2',
'doc_dokumenttype2',
'integrationsdata2',
   doc3_virkEgenskaber2
) :: dokumentEgenskaberAttrType
;




doc3_docDel2Brelation2Virkning :=	ROW (
	'(2014-02-24, 2015-10-01]' :: TSTZRANGE,
          '800cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx70'
          ) :: Virkning
;

doc3_docDel2Brelation1Virkning :=	ROW (
	'[2012-05-08, infinity)' :: TSTZRANGE,
          '810cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx70'
          ) :: Virkning
;


doc3_docDel1Arelation1Virkning :=	ROW (
	'[2010-04-10, infinity)' :: TSTZRANGE,
          '820cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx71'
          ) :: Virkning
;


doc3_docVariantEgenskaber2AVirkning :=	ROW (
	'[2014-07-12, infinity)' :: TSTZRANGE,
          '840cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx281'
          ) :: Virkning
;

doc3_docVariantEgenskaber1BVirkning :=	ROW (
	'[2015-01-01, infinity)' :: TSTZRANGE,
          '830cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx291'
          ) :: Virkning
;


doc3_docVariantEgenskaber1AVirkning :=	ROW (
	'[2013-02-27, 2015-01-01)' :: TSTZRANGE,
          '850cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx191'
          ) :: Virkning
;

doc3_docDel1AEgenskaberVirkning :=	ROW (
	'[2014-03-30, infinity)' :: TSTZRANGE,
          '860cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx11'
          ) :: Virkning
;

doc3_docDel1A2EgenskaberVirkning :=	ROW (
	'[2010-01-20, 2014-03-20)' :: TSTZRANGE,
          '870cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx113'
          ) :: Virkning
;


doc3_docDel1BEgenskaberVirkning :=	ROW (
	'[2015-10-11, infinity)' :: TSTZRANGE,
          '880cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx12'
          ) :: Virkning
;

doc3_docDel2AEgenskaberVirkning :=	ROW (
	'[2013-02-28, infinity)' :: TSTZRANGE,
          '890cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx13'
          ) :: Virkning
;

doc3_extraRelVirkning1 :=	ROW (
	'[2013-02-28, infinity)' :: TSTZRANGE,
          '900cc58a-3149-414a-9392-dcbcbbccddd9'::uuid,
          'Bruger',
          'NoteEx23'
          ) :: Virkning
;
doc3_extraRelVirkning2 :=	ROW (
	'[2013-02-28, infinity)' :: TSTZRANGE,
          '910cc58a-3149-414a-9392-dcbcbbccddc0'::uuid,
          'Bruger',
          'NoteEx143'
          ) :: Virkning
;


doc3_docVariantEgenskaber1A:=
ROW(
true, --arkivering boolean, 
false, --delvisscannet boolean, 
true, --offentliggoerelse boolean, 
false, --produktion boolean,
 doc3_docVariantEgenskaber1AVirkning
)::DokumentVariantEgenskaberType;

doc3_docVariantEgenskaber1B:=
ROW(
false, --arkivering boolean, 
false, --delvisscannet boolean, 
false, --offentliggoerelse boolean, 
false, --produktion boolean,
 doc3_docVariantEgenskaber1BVirkning
)::DokumentVariantEgenskaberType;


doc3_docVariantEgenskaber2A:=
ROW(
false, --arkivering boolean, 
false, --delvisscannet boolean, 
true, --offentliggoerelse boolean, 
true, --produktion boolean,
 doc3_docVariantEgenskaber2AVirkning
)::DokumentVariantEgenskaberType;


doc3_docDel2Brelation1:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc3_docDel2Brelation1Virkning,
  '700a2dd4-415f-4104-b7a7-84607488c096'::uuid,
  null, --urn,
  'Bruger'
)::DokumentdelRelationType;


doc3_docDel2Brelation2:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc3_docDel2Brelation2Virkning,
  null,
  'urn:cpr 7000000', 
  'Bruger'
)::DokumentdelRelationType;


doc3_docDel1Arelation1:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc3_docDel1Arelation1Virkning,
  '800a2dd4-415f-4104-b7a7-84607488c091'::uuid,
  null, 
  'Bruger'
)::DokumentdelRelationType;

doc3_extraRel1:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc3_extraRelVirkning1,
  '720a2dd4-415f-4104-b7a7-84607488c027'::uuid,
  null, 
  'Bruger'
)::DokumentdelRelationType;


doc3_extraRel2:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc3_extraRelVirkning2,
  '730a2dd4-415f-4104-b7a7-84607488c019'::uuid,
  null, 
  'Bruger'
)::DokumentdelRelationType;



doc3_docDel1AEgenskaber:= ROW(
1, --indeks int,
'del_indhold1_doc3', 
'del_lokation1_doc3', 
'del_mimetype1',
 doc3_docDel1AEgenskaberVirkning 
)::DokumentDelEgenskaberType
;

doc3_docDel1A2Egenskaber:=ROW(
2, --indeks int,
'del_indhold4_doc3', 
'del_lokation4_doc3', 
'del_mimetype4_doc3',
 doc3_docDel1A2EgenskaberVirkning 
)::DokumentDelEgenskaberType
;

doc3_docDel1BEgenskaber:= ROW(
98, --indeks int,
'del_indhold2_doc3', 
'del_lokation2_doc3', 
'del_mimetype2_doc3',
 doc3_docDel1BEgenskaberVirkning 
)::DokumentDelEgenskaberType
;

doc3_docDel2AEgenskaber:= ROW(
8, --indeks int,
'del_indhold3_doc3', 
'del_lokation3_doc3', 
'del_mimetype3_doc3',
 doc3_docDel2AEgenskaberVirkning 
)::DokumentDelEgenskaberType
;


doc3_docDel1A:=
ROW(
'doc_deltekst1A',
  ARRAY[doc3_docDel1AEgenskaber,doc3_docDel1A2Egenskaber],
  ARRAY[doc3_docDel1Arelation1]
)::DokumentDelType;

doc3_docDel1B:=
ROW(
'doc_deltekst1B_doc3',
  ARRAY[doc3_docDel1BEgenskaber],
  null--ARRAY[]::DokumentdelRelationType[]
)::DokumentDelType;

doc3_docDel2A:=
ROW(
'doc_deltekst2A',
  ARRAY[doc3_docDel2AEgenskaber],
  null--ARRAY[]::DokumentdelRelationType[]
)::DokumentDelType;

doc3_docDel2B:=
ROW(
'doc_deltekst2B_doc3',
  null,--ARRAY[]::DokumentDelEgenskaberType[],
  ARRAY[doc3_docDel2Brelation1,doc3_docDel2Brelation2]
)::DokumentDelType;


doc3_docVariant1 := ROW (
	'doc_varianttekst2_1',
  	ARRAY[doc3_docVariantEgenskaber1B,doc3_docVariantEgenskaber1A],
  	ARRAY[doc3_docDel1A,
  	ROW(
  		'doc_deltekst1B',
  		ARRAY[doc3_docDel1BEgenskaber],
  		ARRAY[doc3_extraRel1,doc3_extraRel2]
  		)::DokumentDelType
  	]
)::DokumentVariantType;


doc3_docVariant2 := ROW (
	'doc_varianttekst2',
  ARRAY[doc3_docVariantEgenskaber2A],
  ARRAY[doc3_docDel2A,doc3_docDel2B]
)::DokumentVariantType;

doc3_registrering := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	doc3_uuidRegistrering,
	'Test Note 500') :: RegistreringBase
	,
ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

doc3_new_uuid := as_create_or_import_dokument(doc3_registrering);
/***************************************************/
read_doc1 := as_read_dokument(doc1_new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

--raise notice 'read_doc1:%',to_json(read_doc1);

read_doc2 := as_read_dokument(doc2_new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

--raise notice 'read_doc2:%',to_json(read_doc2);


read_doc3 := as_read_dokument(doc3_new_uuid,
	null, --registrering_tstzrange
	null --virkning_tstzrange
	);

--raise notice 'read_doc3:%',to_json(read_doc3);

/***************************************************/


search_reg11:= ROW (
	null --base reg
	,null -- fremdrift ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
	,ARRAY[
	 ROW (
		 null --'doc2_brugervendtnoegle1',
		,'doc_beskrivelse1'
		,null --'2015-09-30'::date,
		,null --'doc2_kassationskode1', 
		,null --3, --major int
		,null --minor int
		,null --ROW('doc2_Offentlighedundtaget_AlternativTitel1','doc2_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
		,null --'doc2_titel1',
		,null --'doc2_dokumenttype1',
		,null --'integrationsdata1',
		,null--   doc2_virkEgenskaber1
	) :: dokumentEgenskaberAttrType
	]::dokumentEgenskaberAttrType[]
	  -- egenskaber ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
	,null --relations ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
	,ARRAY[
	ROW(
		'doc_varianttekst2_1'
		,null --egenskaber
		,null --dele
		)::DokumentVariantType
	]::DokumentVariantType[]
	--null --variants ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

expected_result11:=ARRAY[doc1_new_uuid,doc3_new_uuid]::uuid[];

search_result11:=as_search_dokument(null,null,search_reg11,null);


RETURN NEXT ok(expected_result11 @> search_result11 and search_result11 @>expected_result11 and coalesce(array_length(search_result11,1),0)=coalesce(array_length(expected_result11,1),0), 'search dokument #11.');

/***************************************************/



search_reg12:= ROW (
	null --base reg
	,null -- fremdrift ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
	,ARRAY[
	 ROW (
		 null --'doc2_brugervendtnoegle1',
		,null --'doc_beskrivelse1'
		,null --'2015-09-30'::date,
		,'doc_kassationskode1'
		,null --3, --major int
		,null --minor int
		,null --ROW('doc2_Offentlighedundtaget_AlternativTitel1','doc2_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
		,null --'doc2_titel1',
		,null --'doc2_dokumenttype1',
		,null --'integrationsdata1',
		,null--   doc2_virkEgenskaber1
	) :: dokumentEgenskaberAttrType
	]::dokumentEgenskaberAttrType[]
	  -- egenskaber ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
	,null --relations ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
	,ARRAY[
	ROW(
		'doc_varianttekst2_1'
		,null --egenskaber
		,null --dele
		)::DokumentVariantType
	]::DokumentVariantType[]
	--null --variants ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

expected_result12:=ARRAY[doc1_new_uuid]::uuid[];

search_result12:=as_search_dokument(null,null,search_reg12,null);


RETURN NEXT ok(expected_result12 @> search_result12 and search_result12 @>expected_result12 and coalesce(array_length(search_result12,1),0)=coalesce(array_length(expected_result12,1),0), 'search dokument #12.');

/***************************************************/


search_reg13:= ROW (
	null --base reg
	,null -- fremdrift ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
	,null -- egenskaber ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
	,null --relations ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
	,ARRAY[
	ROW(
		'doc_varianttekst2_1'
		,ARRAY [ROW(
				false, --arkivering boolean, 
				null, --delvisscannet boolean, 
				null, --offentliggoerelse boolean, 
				null, --produktion boolean,
				null
				)::DokumentVariantEgenskaberType
			,
			ROW(
				null, --arkivering boolean, 
				null, --delvisscannet boolean, 
				false, --offentliggoerelse boolean, 
				null, --produktion boolean,
				null
				)::DokumentVariantEgenskaberType
		]::DokumentVariantEgenskaberType[]
		,null --dele
		)::DokumentVariantType
	]::DokumentVariantType[]
	--null --variants ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

expected_result13:=ARRAY[doc3_new_uuid]::uuid[];

search_result13:=as_search_dokument(null,null,search_reg13,null);


RETURN NEXT ok(expected_result13 @> search_result13 and search_result13 @>expected_result13 and coalesce(array_length(search_result13,1),0)=coalesce(array_length(expected_result13,1),0), 'search dokument #13.');

/***************************************************/


search_reg14:= ROW (
	null --base reg
	,null -- fremdrift ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
	,null -- egenskaber ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
	,null --relations ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
	,ARRAY[
	ROW(
		'doc%'
		,ARRAY [ROW(
				null, --arkivering boolean, 
				true, --delvisscannet boolean, 
				null, --offentliggoerelse boolean, 
				null, --produktion boolean,
				null
				)::DokumentVariantEgenskaberType
			
		]::DokumentVariantEgenskaberType[]
		,null --dele
		)::DokumentVariantType
	]::DokumentVariantType[]
	--null --variants ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

expected_result14:=ARRAY[doc1_new_uuid,doc2_new_uuid]::uuid[];

search_result14:=as_search_dokument(null,null,search_reg14,null);


RETURN NEXT ok(expected_result14 @> search_result14 and search_result14 @>expected_result14 and coalesce(array_length(search_result14,1),0)=coalesce(array_length(expected_result14,1),0), 'search dokument #14.');

/***************************************************/


search_reg15:= ROW (
	null --base reg
	,null -- fremdrift ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
	,null -- egenskaber ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
	,null --relations ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
	,ARRAY[
	ROW(
		'doc%'
		,ARRAY [ROW(
				null, --arkivering boolean, 
				true, --delvisscannet boolean, 
				null, --offentliggoerelse boolean, 
				null, --produktion boolean,
				ROW (
			'[2010-03-27, 2010-04-01)' :: TSTZRANGE
          	,null --'471cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          	,null --'Bruger',
          	,null --'NoteEx191'
          	) :: Virkning
				)::DokumentVariantEgenskaberType
			
		]::DokumentVariantEgenskaberType[]
		,null --dele
		)::DokumentVariantType
	]::DokumentVariantType[]
	--null --variants ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

expected_result15:=ARRAY[doc2_new_uuid]::uuid[];

search_result15:=as_search_dokument(null,null,search_reg15,null);


RETURN NEXT ok(expected_result15 @> search_result15 and search_result15 @>expected_result15 and coalesce(array_length(search_result15,1),0)=coalesce(array_length(expected_result15,1),0), 'search dokument #15.');

/***************************************************/

search_reg16:= ROW (
	null --base reg
	,null -- fremdrift ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
	,null -- egenskaber ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
	,null --relations ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
	,ARRAY[
	ROW(
		'doc_varianttekst2_1'
		,ARRAY [ROW(
				null, --arkivering boolean, 
				false, --delvisscannet boolean, 
				null, --offentliggoerelse boolean, 
				null, --produktion boolean,
				null --virkning
				)::DokumentVariantEgenskaberType
			
		]::DokumentVariantEgenskaberType[]
		,ARRAY[
		ROW(
			'doc_deltekst1A'
			,ARRAY[
			 ROW(
				null --1, --indeks int,
				,null --'del_indhold1', 
				, null --'del_lokation1', 
				,'del_mimetype1'
				,null
				)::DokumentDelEgenskaberType
			 ,
			  ROW(
				null --1, --indeks int,
				,'del_indhold1_doc3' --'del_indhold1', 
				, null --'del_lokation1', 
				,null
				,null
				)::DokumentDelEgenskaberType
			]::DokumentDelEgenskaberType[]   --egenskaber
			,null --relationer
			)::DokumentDelType
		]::DokumentDelType[]

		)::DokumentVariantType
	]::DokumentVariantType[]
	--null --variants ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

expected_result16:=ARRAY[doc3_new_uuid]::uuid[];

search_result16:=as_search_dokument(null,null,search_reg16,null);


RETURN NEXT ok(expected_result16 @> search_result16 and search_result16 @>expected_result16 and coalesce(array_length(search_result16,1),0)=coalesce(array_length(expected_result16,1),0), 'search dokument #16.');

/***************************************************/


search_reg17:= ROW (
	null --base reg
	,null -- fremdrift ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
	,null -- egenskaber ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
	,null --relations ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
	,ARRAY[
	ROW(
		null --varianttekst
		,null --variantegenskaber
		,ARRAY[
		ROW(
			null --deltekst
			,ARRAY[
			 ROW(
				null --1, --indeks int,
				,null --'del_indhold1', 
				, null --'del_lokation1', 
				,'del_mimetype1'
					,ROW (
					'[2011-01-20, 2011-01-25]' :: TSTZRANGE,
	         		null,
	          		null,
	          		null
	          		) :: Virkning
				)::DokumentDelEgenskaberType
			]::DokumentDelEgenskaberType[]   --egenskaber
			,null --del relationer
			)::DokumentDelType
		]::DokumentDelType[]

		)::DokumentVariantType
	]::DokumentVariantType[]
	--null --variants ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

expected_result17:=ARRAY[doc2_new_uuid]::uuid[];

search_result17:=as_search_dokument(null,null,search_reg17,null);


RETURN NEXT ok(expected_result17 @> search_result17 and search_result17 @>expected_result17 and coalesce(array_length(search_result17,1),0)=coalesce(array_length(expected_result17,1),0), 'search dokument #17.');

/***************************************************/

search_reg18:= ROW (
	null --base reg
	,null -- fremdrift ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
	,null -- egenskaber ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
	,null --relations ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
	,ARRAY[
	ROW(
		null --varianttekst
		,null --variantegenskaber
		,ARRAY[
		ROW(
			null --deltekst
			,ARRAY[
			 ROW(
				null --1, --indeks int,
				,null --'del_indhold1', 
				, null --'del_lokation1', 
				,'del_mimetype1'
					,ROW (
					'[2014-05-20, 2014-05-25]' :: TSTZRANGE,
	         		null,
	          		null,
	          		null
	          		) :: Virkning
				)::DokumentDelEgenskaberType
			]::DokumentDelEgenskaberType[]   --egenskaber
			,null --del relationer
			)::DokumentDelType
		]::DokumentDelType[]

		)::DokumentVariantType
	]::DokumentVariantType[]
	--null --variants ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

expected_result18:=ARRAY[doc1_new_uuid,doc3_new_uuid]::uuid[];

search_result18:=as_search_dokument(null,null,search_reg18,null);


RETURN NEXT ok(expected_result18 @> search_result18 and search_result18 @>expected_result18 and coalesce(array_length(search_result18,1),0)=coalesce(array_length(expected_result18,1),0), 'search dokument #18.');

/***************************************************/

search_reg19
:= ROW (
	null --base reg
	,null -- fremdrift ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
	,null -- egenskaber ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
	,null --relations ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
	,ARRAY[
	ROW(
		null --varianttekst
		,null --variantegenskaber
		,ARRAY[
		ROW(
			null --deltekst
			,ARRAY[
			 ROW(
				null --1, --indeks int,
				,null --'del_indhold1', 
				, null --'del_lokation1', 
				,'del_mimetype1'
					,ROW (
					'[2014-03-25, 2014-03-26)' :: TSTZRANGE,
	         		null,
	          		null,
	          		null
	          		) :: Virkning
				)::DokumentDelEgenskaberType
			]::DokumentDelEgenskaberType[]   --egenskaber
			,null --del relationer
			)::DokumentDelType
		]::DokumentDelType[]

		)::DokumentVariantType
	]::DokumentVariantType[]
	--null --variants ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

expected_result19
:=ARRAY[]::uuid[];

search_result19
:=as_search_dokument(null,null,search_reg19
,null);


RETURN NEXT ok(expected_result19 @> search_result19 and search_result19 @>expected_result19 and coalesce(array_length(search_result19 ,1),0)=coalesce(array_length(expected_result19,1),0), 'search dokument #19.');

/***************************************************/

search_reg20
:= ROW (
	null --base reg
	,null -- fremdrift ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
	,null -- egenskaber ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
	,null --relations ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
	,ARRAY[
	ROW(
		null  --varianttekst
		,null --variantegenskaber
		,ARRAY[
		ROW(
			null --deltekst
			,ARRAY[
			 ROW(
				null --1, --indeks int,
				,null --'del_indhold1', 
				, null --'del_lokation1', 
				,'del_mimetype1'
				,null	
				)::DokumentDelEgenskaberType
			]::DokumentDelEgenskaberType[]   --egenskaber
			,null --del relationer
			)::DokumentDelType
		]::DokumentDelType[]

		)::DokumentVariantType
	]::DokumentVariantType[]
	--null --variants ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

expected_result20:=ARRAY[doc1_new_uuid,doc2_new_uuid,doc3_new_uuid]::uuid[];

search_result20
:=as_search_dokument(null,null,search_reg20
,null);


RETURN NEXT ok(expected_result20 @> search_result20 and search_result20 @>expected_result20 and coalesce(array_length(search_result20 ,1),0)=coalesce(array_length(expected_result20,1),0), 'search dokument #20.');

/***************************************************/



search_reg21
:= ROW (
	null --base reg
	,null -- fremdrift ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
	,null -- egenskaber ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
	,null --relations ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
	,ARRAY[
	ROW(
		'doc_varianttekst2_1' --null --varianttekst
		,null --variantegenskaber
		,ARRAY[
		ROW(
			null --deltekst
			,ARRAY[
			 ROW(
				null --1, --indeks int,
				,null --'del_indhold1', 
				, null --'del_lokation1', 
				,'del_mimetype1'
				,null	
				)::DokumentDelEgenskaberType
			]::DokumentDelEgenskaberType[]   --egenskaber
			, ARRAY[
				ROW(
					'underredigeringaf'
  					,null --virkning Virkning,
  					,'800a2dd4-415f-4104-b7a7-84607488c091'
  					,null
  					,'Bruger'
					)::DokumentdelRelationType
			]::DokumentdelRelationType[]
			)::DokumentDelType
		]::DokumentDelType[]
		)::DokumentVariantType
	]::DokumentVariantType[]
	--null --variants ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

expected_result21:=ARRAY[doc3_new_uuid]::uuid[];

search_result21
:=as_search_dokument(null,null,search_reg21
,null);


RETURN NEXT ok(expected_result21 @> search_result21 and search_result21 @>expected_result21 and coalesce(array_length(search_result21 ,1),0)=coalesce(array_length(expected_result21,1),0), 'search dokument #21.');

/***************************************************/


search_reg22
:= ROW (
	null --base reg
	,null -- fremdrift ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
	,null -- egenskaber ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
	,null --relations ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
	,ARRAY[
	ROW(
		'doc_varianttekst2_1' --null --varianttekst
		,null --variantegenskaber
		,ARRAY[
		ROW(
			'doc_deltekst1A' --deltekst
			,ARRAY[
			 ROW(
				null --1, --indeks int,
				,null --'del_indhold1', 
				, null --'del_lokation1', 
				,'del_mimetype1'
				,null	
				)::DokumentDelEgenskaberType
			]::DokumentDelEgenskaberType[]   --egenskaber
			, ARRAY[
				ROW(
					'underredigeringaf'
  					,null --virkning Virkning,
  					,null
  					,null
  					,'Bruger'
					)::DokumentdelRelationType
			]::DokumentdelRelationType[]
			)::DokumentDelType
		]::DokumentDelType[]
		)::DokumentVariantType
	]::DokumentVariantType[]
	--null --variants ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

expected_result22:=ARRAY[doc3_new_uuid,doc1_new_uuid]::uuid[];

search_result22
:=as_search_dokument(null,null,search_reg22
,null);


RETURN NEXT ok(expected_result22 @> search_result22 and search_result22 @>expected_result22 and coalesce(array_length(search_result22 ,1),0)=coalesce(array_length(expected_result22,1),0), 'search dokument #22.');

/***************************************************/

/***************************************************/


search_reg23

:= ROW (
	null --base reg
	,null -- fremdrift ARRAY[doc3_dokumentFremdrift]::dokumentFremdriftTilsType[],
	,null -- egenskaber ARRAY[doc3_dokumentEgenskab1,doc3_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
	,null --relations ARRAY[doc3_dokumentRelBesvarelser1,doc3_dokumentRelAnsvarlig,doc3_dokumentRelBesvarelser2],
	,ARRAY[
	ROW(
		'doc_varianttekst2_1' --null --varianttekst
		,null --variantegenskaber
		,ARRAY[
		ROW(
			'doc_deltekst1A' --deltekst
			,ARRAY[
			 ROW(
				null --1, --indeks int,
				,null --'del_indhold1', 
				, null --'del_lokation1', 
				,'del_mimetype1'
				,null	
				)::DokumentDelEgenskaberType
			]::DokumentDelEgenskaberType[]   --egenskaber
			, ARRAY[
				ROW(
					'underredigeringaf'
  					,ROW (
					'[2010-01-10, 2010-08-30)' :: TSTZRANGE
          			,null --'771cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          			,null--'Bruger',
          			,null --'NoteEx71'
          			) :: Virkning --virkning Virkning,
  					,null
  					,null
  					,'Bruger'
					)::DokumentdelRelationType
			]::DokumentdelRelationType[]
			)::DokumentDelType
		]::DokumentDelType[]
		)::DokumentVariantType
	]::DokumentVariantType[]
	--null --variants ARRAY[doc3_docVariant1,doc3_docVariant2]
) :: dokumentRegistreringType
;

expected_result23
:=ARRAY[doc3_new_uuid]::uuid[];

search_result23

:=as_search_dokument(null,null,search_reg23

,null);


RETURN NEXT ok(expected_result23 @> search_result23 and search_result23 @>expected_result23 and coalesce(array_length(search_result23,1),0)=coalesce(array_length(expected_result23,1),0), 'search dokument #23.');

/***************************************************/

expected_result24
:=ARRAY[doc2_new_uuid]::uuid[];

search_result24:=as_search_dokument(
	null
	,null --dokument_uuid uuid,
	,null --registreringObj DokumentRegistreringType,
	,null --virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	,null --maxResults int = 2147483647,
	,null --anyAttrValueArr text[] = '{}'::text[],
	,array[doc2_uuidBesvarelser1]::uuid[]
	,null --anyurnArr text[] = '{}'::text[],
	);


RETURN NEXT ok(expected_result24 @> search_result24 and search_result24 @>expected_result24 and coalesce(array_length(search_result24,1),0)=coalesce(array_length(expected_result24,1),0), 'search dokument #24.');



/***************************************************/

expected_result25
:=ARRAY[doc1_new_uuid]::uuid[];

search_result25:=as_search_dokument(
	null
	,null --dokument_uuid uuid,
	,null --registreringObj DokumentRegistreringType,
	,null --virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	,null --maxResults int = 2147483647,
	,null --anyAttrValueArr text[] = '{}'::text[],
	,array['b24a2dd4-415f-4104-b7a7-84607488c091'::uuid]::uuid[]
	,null --anyurnArr text[] = '{}'::text[],
	);


RETURN NEXT ok(expected_result25 @> search_result25 and search_result25 @>expected_result25 and coalesce(array_length(search_result25,1),0)=coalesce(array_length(expected_result25,1),0), 'search dokument #25.');


/***************************************************/

expected_result26
:=ARRAY[doc1_new_uuid]::uuid[];

search_result26:=as_search_dokument(
	null
	,null --dokument_uuid uuid,
	,null --registreringObj DokumentRegistreringType,
	,null --virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	,null --maxResults int = 2147483647,
	,null --anyAttrValueArr text[] = '{}'::text[],
	,null --array['b24a2dd4-415f-4104-b7a7-84607488c091'::uuid]::uuid[]
	,array[doc1_urnBesvarelser2] --anyurnArr text[] = '{}'::text[],
	);


RETURN NEXT ok(expected_result26 @> search_result26 and search_result26 @>expected_result26 and coalesce(array_length(search_result26,1),0)=coalesce(array_length(expected_result26,1),0), 'search dokument #26.');

/***************************************************/

expected_result27
:=ARRAY[doc3_new_uuid]::uuid[];

search_result27:=as_search_dokument(
	null
	,null --dokument_uuid uuid,
	,null --registreringObj DokumentRegistreringType,
	,null --virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	,null --maxResults int = 2147483647,
	,null --anyAttrValueArr text[] = '{}'::text[],
	,null --array['b24a2dd4-415f-4104-b7a7-84607488c091'::uuid]::uuid[]
	,array['urn:cpr 7000000'] --anyurnArr text[] = '{}'::text[],
	);


RETURN NEXT ok(expected_result27 @> search_result27 and search_result27 @>expected_result27 and coalesce(array_length(search_result27,1),0)=coalesce(array_length(expected_result27,1),0), 'search dokument #27.');


/***************************************************/
expected_result28
:=ARRAY[doc2_new_uuid]::uuid[];

search_result28:=as_search_dokument(
	null
	,null --dokument_uuid uuid,
	,null --registreringObj DokumentRegistreringType,
	,null --virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	,null --maxResults int = 2147483647,
	,array['doc2_kassationskode1']::text[] --anyAttrValueArr text[] = '{}'::text[],
	,null --array['b24a2dd4-415f-4104-b7a7-84607488c091'::uuid]::uuid[]
	,null --array['urn:cpr 7000000'] --anyurnArr text[] = '{}'::text[],
	);


RETURN NEXT ok(expected_result28 @> search_result28 and search_result28 @>expected_result28 and coalesce(array_length(search_result28,1),0)=coalesce(array_length(expected_result28,1),0), 'search dokument #28.');



/***************************************************/
expected_result29
:=ARRAY[doc1_new_uuid,doc2_new_uuid,doc3_new_uuid]::uuid[];

search_result29:=as_search_dokument(
	null
	,null --dokument_uuid uuid,
	,null --registreringObj DokumentRegistreringType,
	,null --virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	,null --maxResults int = 2147483647,
	,array['del_mimetype1%']::text[] --anyAttrValueArr text[] = '{}'::text[],
	,null --array['b24a2dd4-415f-4104-b7a7-84607488c091'::uuid]::uuid[]
	,null --array['urn:cpr 7000000'] --anyurnArr text[] = '{}'::text[],
	);


RETURN NEXT ok(expected_result29 @> search_result29 and search_result29 @>expected_result29 and coalesce(array_length(search_result29,1),0)=coalesce(array_length(expected_result29,1),0), 'search dokument #29.');

/***************************************************/
expected_result30
:=ARRAY[doc1_new_uuid,doc3_new_uuid]::uuid[];

search_result30:=as_search_dokument(
	null
	,null --dokument_uuid uuid,
	,null --registreringObj DokumentRegistreringType,
	,TSTZRANGE(current_timestamp,current_timestamp,'[]') --virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	,null --maxResults int = 2147483647,
	,array['del_mimetype1']::text[] --anyAttrValueArr text[] = '{}'::text[],
	,null --array['b24a2dd4-415f-4104-b7a7-84607488c091'::uuid]::uuid[]
	,null --array['urn:cpr 7000000'] --anyurnArr text[] = '{}'::text[],
	);


--RAISE NOTICE 'expected_result30:%',to_json(expected_result30);
--RAISE NOTICE 'search_result30:%',to_json(search_result30);

RETURN NEXT ok(expected_result30 @> search_result30 and search_result30 @>expected_result30 and coalesce(array_length(search_result30,1),0)=coalesce(array_length(expected_result30,1),0), 'search dokument #30.');


/***************************************************/

expected_result31:=ARRAY[doc2_new_uuid]::uuid[];

search_result31:=as_search_dokument(
	null
	,null --dokument_uuid uuid,
	,null --registreringObj DokumentRegistreringType,
	,null --virkningSoeg TSTZRANGE, -- = TSTZRANGE(current_timestamp,current_timestamp,'[]'),
	,null --maxResults int = 2147483647,
	,array['doc2_Offentlighedundtaget_Hjemmel1']::text[] --anyAttrValueArr text[] = '{}'::text[],
	,null --array['b24a2dd4-415f-4104-b7a7-84607488c091'::uuid]::uuid[]
	,null --array['urn:cpr 7000000'] --anyurnArr text[] = '{}'::text[],
	);


--RAISE NOTICE 'expected_result31:%',to_json(expected_result31);
--RAISE NOTICE 'search_result31:%',to_json(search_result31);

RETURN NEXT ok(expected_result31 @> search_result31 and search_result31 @>expected_result31 and coalesce(array_length(search_result31,1),0)=coalesce(array_length(expected_result31,1),0), 'search dokument #31.');







END;
$$;
