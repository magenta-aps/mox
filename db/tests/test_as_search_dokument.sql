-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
'10-31-2015'::date,
'doc_kassationskode1', 
4, --major int
9, --minor int
ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
'doc_titel1',
'doc_dokumenttype1',
   doc1_virkEgenskaber1
) :: dokumentEgenskaberAttrType
;

doc1_dokumentEgenskab2 := ROW (
'doc_brugervendtnoegle2',
'doc_beskrivelse2', 
'09-20-2014'::date,
'doc_kassationskode2', 
5, --major int
10, --minor int
ROW('doc_Offentlighedundtaget_AlternativTitel2','doc_Offentlighedundtaget_Hjemmel2') ::OffentlighedundtagetType, --offentlighedundtagettype,
'doc_titel2',
'doc_dokumenttype2',
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
  null, --relMaalUrn,
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
			,'10-31-2015'::date
			,NULL --'doc_kassationskode1', 
			,NULL --4, --major int
			,NULL --9, --minor int
			,NULL --ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
			,NULL --'doc_titel1',
			,NULL --'doc_dokumenttype1',
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
			,'10-30-2015'::date
			,NULL --'doc_kassationskode1', 
			,NULL --4, --major int
			,NULL --9, --minor int
			,NULL --ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
			,NULL --'doc_titel1',
			,NULL --'doc_dokumenttype1',
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






END;
$$;