-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_list_dokument()
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
	doc2_uuidAnsvarlig uuid :='17109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	doc2_uuidBesvarelser1 uuid :='27160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;
	--uuidBesvarelser2 uuid :='08533179-fedb-4aa7-8902-ab34a219eed9'::uuid;
	doc2_urnBesvarelser2 text:='urn:isbn:9451450523'::text;
	doc2_uuidRegistrering uuid :='3f368584-4c3e-4ba4-837b-da2b1eee37c9'::uuid;
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

	actual_dokuments1 DokumentType[];
	expected_dokuments1 DokumentType[];

	doc1_override_timeperiod TSTZRANGE;
	doc2_override_timeperiod TSTZRANGE;

	actual_dokuments2 DokumentType[];
	expected_dokuments2 DokumentType[];

	actual_dokuments3 DokumentType[];
	expected_dokuments3 DokumentType[];

	actual_dokuments4 DokumentType[];
	expected_dokuments4 DokumentType[];

	actual_dokuments5 DokumentType[];
	expected_dokuments5 DokumentType[];

	document5 DokumentType;

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
	'[2015-05-10, infinity)' :: TSTZRANGE,
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
	'doc_varianttekst1',
  	ARRAY[doc1_docVariantEgenskaber1B,doc1_docVariantEgenskaber1A],
  	ARRAY[doc1_docDel1A,doc1_docDel1B]
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


/**************************************************************/
/*						Create doc 2						  */
/**************************************************************/


doc2_virkEgenskaber1 :=	ROW (
	'[2014-02-20, infinity)' :: TSTZRANGE,
          'c71cc58a-3149-414a-9392-dcbcbbccddfe'::uuid,
          'Bruger',
          'NoteEx13'
          ) :: Virkning
;


doc2_virkEgenskaber2 :=	ROW (
	'[2013-11-30, 2014-02-20)' :: TSTZRANGE,
          'd71cc58a-3149-414a-9392-dcbcbbccddf7'::uuid,
          'Bruger',
          'NoteEx11'
          ) :: Virkning
;


doc2_virkAnsvarlig :=	ROW (
	'[2014-04-10, infinity)' :: TSTZRANGE,
          'a71cc58a-3149-414a-9392-dcbcbbccddf7'::uuid,
          'Bruger',
          'NoteEx23'
          ) :: Virkning
;

doc2_virkBesvarelser1 :=	ROW (
	'[2015-12-09, infinity)' :: TSTZRANGE,
          '371cc58a-3149-414a-9392-dcbcbbccddf9'::uuid,
          'Bruger',
          'NoteEx239'
          ) :: Virkning
;


doc2_virkBesvarelser2 :=	ROW (
	'[2015-04-10, 2017-05-10)' :: TSTZRANGE,
          'c71cc58a-3149-414a-9392-dcbcbbccddf1'::uuid,
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;

doc2_virkFremdrift := ROW (
	'[2011-04-20, infinity)' :: TSTZRANGE,
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
'doc_brugervendtnoegle2_1',
'doc_beskrivelse2_1', 
'2014-01-10'::date,
'doc_kassationskode2_1', 
11, --major int
2, --minor int
ROW('doc_Offentlighedundtaget_AlternativTitel2_1','doc_Offentlighedundtaget_Hjemmel2_1') ::OffentlighedundtagetType, --offentlighedundtagettype,
'doc_titel2_1',
'doc_dokumenttype2_1',
'integrationsdata2_1',
   doc2_virkEgenskaber1
) :: dokumentEgenskaberAttrType
;

doc2_dokumentEgenskab2 := ROW (
'doc_brugervendtnoegle2_2',
'doc_beskrivelse2_2', 
'2013-08-28'::date,
'doc_kassationskode2_2', 
12, --major int
6, --minor int
ROW('doc_Offentlighedundtaget_AlternativTitel2_2','doc_Offentlighedundtaget_Hjemmel2_2') ::OffentlighedundtagetType, --offentlighedundtagettype,
'doc_titel2_2',
'doc_dokumenttype2_2',
'integrationsdata2_2',
   doc2_virkEgenskaber2
) :: dokumentEgenskaberAttrType
;




doc2_docDel2Brelation2Virkning :=	ROW (
	'(2012-07-12, 2014-10-01]' :: TSTZRANGE,
          '071cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx70'
          ) :: Virkning
;

doc2_docDel2Brelation1Virkning :=	ROW (
	'[2013-05-07, infinity)' :: TSTZRANGE,
          '171cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx70'
          ) :: Virkning
;


doc2_docDel1Arelation1Virkning :=	ROW (
	'[2013-10-15, infinity)' :: TSTZRANGE,
          '271cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx71'
          ) :: Virkning
;


doc2_docVariantEgenskaber2AVirkning :=	ROW (
	'[2014-07-12, infinity)' :: TSTZRANGE,
          '371cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx281'
          ) :: Virkning
;

doc2_docVariantEgenskaber1BVirkning :=	ROW (
	'[2014-06-11, infinity)' :: TSTZRANGE,
          '471cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx291'
          ) :: Virkning
;


doc2_docVariantEgenskaber1AVirkning :=	ROW (
	'[2013-02-27, 2014-06-11)' :: TSTZRANGE,
          '571cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx191'
          ) :: Virkning
;

doc2_docDel1AEgenskaberVirkning :=	ROW (
	'[2014-03-30, infinity)' :: TSTZRANGE,
          '671cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx11'
          ) :: Virkning
;

doc2_docDel1A2EgenskaberVirkning :=	ROW (
	'[2010-01-20, 2014-03-20)' :: TSTZRANGE,
          '471cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx113'
          ) :: Virkning
;


doc2_docDel1BEgenskaberVirkning :=	ROW (
	'[2015-10-11, infinity)' :: TSTZRANGE,
          '871cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx12'
          ) :: Virkning
;

doc2_docDel2AEgenskaberVirkning :=	ROW (
	'[2013-02-28, infinity)' :: TSTZRANGE,
          '001cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx13'
          ) :: Virkning
;


doc2_docVariantEgenskaber1A:=
ROW(
false, --arkivering boolean, 
false, --delvisscannet boolean, 
true, --offentliggoerelse boolean, 
true, --produktion boolean,
 doc2_docVariantEgenskaber1AVirkning
)::DokumentVariantEgenskaberType;

doc2_docVariantEgenskaber1B:=
ROW(
true, --arkivering boolean, 
false, --delvisscannet boolean, 
true, --offentliggoerelse boolean, 
true, --produktion boolean,
 doc2_docVariantEgenskaber1BVirkning
)::DokumentVariantEgenskaberType;


doc2_docVariantEgenskaber2A:=
ROW(
false, --arkivering boolean, 
false, --delvisscannet boolean, 
false, --offentliggoerelse boolean, 
false, --produktion boolean,
 doc2_docVariantEgenskaber2AVirkning
)::DokumentVariantEgenskaberType;


doc2_docDel2Brelation1:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc2_docDel2Brelation1Virkning,
  '124a2dd4-415f-4104-b7a7-84607488c096'::uuid,
  null, --urn,
  'Bruger'
)::DokumentdelRelationType;


doc2_docDel2Brelation2:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc2_docDel2Brelation2Virkning,
  null,
  'urn:cpr 8883394', 
  'Bruger'
)::DokumentdelRelationType;


doc2_docDel1Arelation1:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  doc2_docDel2Brelation2Virkning,
  '524a2dd4-415f-4104-b7a7-84607488c091'::uuid,
  null, 
  'Bruger'
)::DokumentdelRelationType;


doc2_docDel1AEgenskaber:= ROW(
1, --indeks int,
'del_indhold2_1', 
'del_lokation2_1', 
'del_mimetype2_1',
 doc2_docDel1AEgenskaberVirkning 
)::DokumentDelEgenskaberType
;

doc2_docDel1A2Egenskaber:=ROW(
2, --indeks int,
'del_indhold2_4', 
'del_lokation2_4', 
'del_mimetype2_4',
 doc2_docDel1A2EgenskaberVirkning 
)::DokumentDelEgenskaberType
;

doc2_docDel1BEgenskaber:= ROW(
98, --indeks int,
'del_indhold2_2', 
'del_lokation2_2', 
'del_mimetype2_2',
 doc2_docDel1BEgenskaberVirkning 
)::DokumentDelEgenskaberType
;

doc2_docDel2AEgenskaber:= ROW(
8, --indeks int,
'del_indhold2_3', 
'del_lokation2_3', 
'del_mimetype2_3',
 doc2_docDel2AEgenskaberVirkning 
)::DokumentDelEgenskaberType
;


doc2_docDel1A:=
ROW(
'doc_deltekst2_1A',
  ARRAY[doc2_docDel1AEgenskaber,doc2_docDel1A2Egenskaber],
  ARRAY[doc2_docDel1Arelation1]
)::DokumentDelType;

doc2_docDel1B:=
ROW(
'doc_deltekst2_1B',
  ARRAY[doc2_docDel1BEgenskaber],
  null--ARRAY[]::DokumentdelRelationType[]
)::DokumentDelType;

doc2_docDel2A:=
ROW(
'doc_deltekst2_2A',
  ARRAY[doc2_docDel2AEgenskaber],
  null--ARRAY[]::DokumentdelRelationType[]
)::DokumentDelType;

doc2_docDel2B:=
ROW(
'doc_deltekst2_2B',
  null,--ARRAY[]::DokumentDelEgenskaberType[],
  ARRAY[doc2_docDel2Brelation1,doc2_docDel2Brelation2]
)::DokumentDelType;


doc2_docVariant1 := ROW (
	'doc_varianttekst2_1',
  	ARRAY[doc2_docVariantEgenskaber1A,doc2_docVariantEgenskaber1B],
  	ARRAY[doc2_docDel1A,doc2_docDel1B]
)::DokumentVariantType;


doc2_docVariant2 := ROW (
	'doc_varianttekst2_2',
  ARRAY[doc2_docVariantEgenskaber2A],
  ARRAY[doc2_docDel2A,doc2_docDel2B]
)::DokumentVariantType;

doc2_registrering := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	doc2_uuidRegistrering,
	'Test Note 50') :: RegistreringBase
	,
ARRAY[doc2_dokumentFremdrift]::dokumentFremdriftTilsType[],
ARRAY[doc2_dokumentEgenskab1,doc2_dokumentEgenskab2]::dokumentEgenskaberAttrType[],
ARRAY[doc2_dokumentRelAnsvarlig,doc2_dokumentRelBesvarelser1,doc2_dokumentRelBesvarelser2],
ARRAY[doc2_docVariant1,doc2_docVariant2]
) :: dokumentRegistreringType
;


doc2_new_uuid := as_create_or_import_dokument(doc2_registrering);

/********************************************************************/


actual_dokuments1:= as_list_dokument(array[doc1_new_uuid,doc2_new_uuid]::uuid[],null,null);


select 
(a.registrering).timeperiod into doc1_override_timeperiod
from dokument_registrering a
where 
dokument_id=doc1_new_uuid;

select 
(a.registrering).timeperiod into doc2_override_timeperiod
from dokument_registrering a
where 
dokument_id=doc2_new_uuid;


expected_dokuments1:= ARRAY[
		ROW(
			doc1_new_uuid,
			ARRAY[
					ROW(
						ROW(
							doc1_override_timeperiod, --this is cheating, but helps the comparison efforts below. (The timeperiod is set during creation/initialization )
							(doc1_registrering.registrering).livscykluskode,
							(doc1_registrering.registrering).brugerref,
							(doc1_registrering.registrering).note 
							)::RegistreringBase
						,doc1_registrering.tilsfremdrift
						,doc1_registrering.attrEgenskaber
						,doc1_registrering.relationer
						,doc1_registrering.varianter
					)::dokumentRegistreringType
				]::dokumentRegistreringType[]
			)::dokumentType
		,
	ROW(
			doc2_new_uuid,
			ARRAY[
					ROW(
						ROW(
							doc2_override_timeperiod, --this is cheating, but helps the comparison efforts below. (The timeperiod is set during creation/initialization )
							(doc2_registrering.registrering).livscykluskode,
							(doc2_registrering.registrering).brugerref,
							(doc2_registrering.registrering).note 
							)::RegistreringBase
						,doc2_registrering.tilsfremdrift
						,doc2_registrering.attrEgenskaber
						,doc2_registrering.relationer
						,doc2_registrering.varianter
					)::dokumentRegistreringType
			]::dokumentRegistreringType[]
			)::dokumentType
	]::dokumentType[];

select array_agg(a.* order by a.id) from unnest(expected_dokuments1) as a into expected_dokuments1;

--raise notice 'list dokument expected_dokuments1:%',to_json(expected_dokuments1);
--raise notice 'list dokument actual_dokuments1:%',to_json(actual_dokuments1);

RETURN NEXT is(
	actual_dokuments1,
	expected_dokuments1,	
	'dokument list test 1');


/******************************************************/
--Test for filtration on virkning



actual_dokuments2 :=as_list_dokument(array[doc1_new_uuid,doc2_new_uuid]::uuid[],null,'(-infinity, 2015-01-01)' :: TSTZRANGE);


expected_dokuments2:= ARRAY[
		ROW(
			doc1_new_uuid,
			ARRAY[
					ROW(
						ROW(
							doc1_override_timeperiod, --this is cheating, but helps the comparison efforts below. (The timeperiod is set during creation/initialization )
							(doc1_registrering.registrering).livscykluskode,
							(doc1_registrering.registrering).brugerref,
							(doc1_registrering.registrering).note 
							)::RegistreringBase
						,null--doc1_registrering.tilsfremdrift
						,ARRAY[doc1_dokumentEgenskab2]::dokumentEgenskaberAttrType[]
						,ARRAY[doc1_dokumentRelAnsvarlig]
						--,doc1_registrering.varianter
						,ARRAY[
							ROW (
								'doc_varianttekst1',
							  	ARRAY[doc1_docVariantEgenskaber1A],
							  	ARRAY[ROW(
								'doc_deltekst1A',
								  ARRAY[doc1_docDel1AEgenskaber,doc1_docDel1A2Egenskaber],
								  null
								)::DokumentDelType]
							)::DokumentVariantType
							,doc1_docVariant2
						]::DokumentVariantType[]
					)::dokumentRegistreringType
				]::dokumentRegistreringType[]
			)::dokumentType
		,
	ROW(
			doc2_new_uuid,
			ARRAY[
					ROW(
						ROW(
							doc2_override_timeperiod, --this is cheating, but helps the comparison efforts below. (The timeperiod is set during creation/initialization )
							(doc2_registrering.registrering).livscykluskode,
							(doc2_registrering.registrering).brugerref,
							(doc2_registrering.registrering).note 
							)::RegistreringBase
						,doc2_registrering.tilsfremdrift
						,doc2_registrering.attrEgenskaber
						,ARRAY[doc2_dokumentRelAnsvarlig]
						,ARRAY[
						ROW (
							'doc_varianttekst2_1',
						  	ARRAY[doc2_docVariantEgenskaber1A,doc2_docVariantEgenskaber1B],
						  	ARRAY[doc2_docDel1A]
						)::DokumentVariantType
						,doc2_docVariant2
						]::DokumentVariantType[]
						--doc2_registrering.varianter
					)::dokumentRegistreringType
			]::dokumentRegistreringType[]
			)::dokumentType
	]::dokumentType[];





select array_agg(a.* order by a.id) from unnest(expected_dokuments2) as a into expected_dokuments2;

--raise notice 'list dokument expected_dokuments2:%',to_json(expected_dokuments2);
--raise notice 'list dokument actual_dokuments2:%',to_json(actual_dokuments2);


RETURN NEXT is(
	actual_dokuments2,
	expected_dokuments2,	
	'dokument list virkning filter test');


/********************************************/
--Test filter on non existing reg time.


actual_dokuments3:=as_list_dokument(array[doc1_new_uuid,doc2_new_uuid]::uuid[], tstzrange(clock_timestamp() - interval '2 hour', clock_timestamp() - interval '1 hour'),'(-infinity, 2015-01-01)' :: TSTZRANGE);

RETURN NEXT ok(coalesce(array_length(actual_dokuments3,1),0)=0,'Test on filter on reg time with no reg.');

--Test filter on current reg 


actual_dokuments4:=as_list_dokument(array[doc1_new_uuid,doc2_new_uuid]::uuid[], tstzrange(clock_timestamp() - interval '1 hour',clock_timestamp()) ,'(-infinity, 2015-01-01)' :: TSTZRANGE);


RETURN NEXT is(
	actual_dokuments4,
	expected_dokuments2,	--Notice using expected_dokuments2 as this is what we expect
	'Test on filter on reg time - current time.');

--Test on list on single uuid

actual_dokuments5:=as_list_dokument(array[doc2_new_uuid]::uuid[],  tstzrange(clock_timestamp() - interval '1 hour',clock_timestamp()) ,'(-infinity, 2015-01-01)' :: TSTZRANGE);

IF expected_dokuments2[1].id = doc2_new_uuid THEN
	expected_dokuments5:=array_append(expected_dokuments5,expected_dokuments2[1]);
ELSE
	expected_dokuments5:=array_append(expected_dokuments5,expected_dokuments2[2]);
END IF;
 

--raise notice 'list dokument expected_dokuments5:%',to_json(expected_dokuments5);
--raise notice 'list dokument actual_dokuments5:%',to_json(actual_dokuments5);


RETURN NEXT is(
	actual_dokuments5,
	expected_dokuments5,	
	'Test list single uuid.');		







END;
$$;
