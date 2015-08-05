-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_create_or_import_dokument()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuid uuid;
	registrering dokumentRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaber1 Virkning;
	virkEgenskaber2 Virkning;
	virkAnsvarlig Virkning;
	virkBesvarelser1 Virkning;
	virkBesvarelser2 Virkning;
	virkFremdrift Virkning;
	dokumentEgenskab1 dokumentEgenskaberAttrType;
	dokumentEgenskab2 dokumentEgenskaberAttrType;
	dokumentFremdrift dokumentFremdriftTilsType;
	dokumentRelAnsvarlig dokumentRelationType;
	dokumentRelBesvarelser1 dokumentRelationType;
	dokumentRelBesvarelser2 dokumentRelationType;
	uuidAnsvarlig uuid :='f7109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid;
	uuidBesvarelser1 uuid :='b7160ce6-ac92-4752-9e82-f17d9e1e52ce'::uuid;
	--uuidBesvarelser2 uuid :='08533179-fedb-4aa7-8902-ab34a219eed9'::uuid;
	urnBesvarelser2 text:='urn:isbn:0451450523'::text;
	uuidRegistrering uuid :='1f368584-4c3e-4ba4-837b-da2b1eee37c9'::uuid;
	actual_fremdrift_virk virkning;
	actual_fremdrift_value dokumentFremdriftTils;
	actual_fremdrift dokumentFremdriftTilsType;
	actual_relationer dokumentRelationType[];
	actual_egenskaber dokumentEgenskaberAttrType[];
	uuid_to_import uuid :='a1819cce-043b-447f-ba5e-92e6a75df918'::uuid;
	uuid_returned_from_import uuid;
	docVariant1 DokumentVariantType;
	docVariant2 DokumentVariantType;
	docVariantEgenskaber1A DokumentVariantEgenskaberType;
	docVariantEgenskaber1AVirkning Virkning;
	docVariantEgenskaber1B DokumentVariantEgenskaberType;
	docVariantEgenskaber1BVirkning Virkning;
	docVariantEgenskaber2A DokumentVariantEgenskaberType;
	docVariantEgenskaber2AVirkning Virkning;	
	docDel1A DokumentDelType;
	docDel1B DokumentDelType;
	docDel2A DokumentDelType;
	docDel2B DokumentDelType;
	docDel1AEgenskaber DokumentDelEgenskaberType;
	docDel1A2Egenskaber DokumentDelEgenskaberType;
	docDel1AEgenskaberVirkning Virkning;
	docDel1A2EgenskaberVirkning Virkning;
	docDel1BEgenskaber DokumentDelEgenskaberType;
	docDel1BEgenskaberVirkning Virkning;
	docDel2AEgenskaber DokumentDelEgenskaberType;
	docDel2AEgenskaberVirkning Virkning;
	docDel1Arelation1 DokumentdelRelationType;
	docDel1Arelation1Virkning Virkning;
	docDel2Brelation1 DokumentdelRelationType;
	docDel2Brelation1Virkning Virkning;
	docDel2Brelation2 DokumentdelRelationType;
	docDel2Brelation2Virkning Virkning;
BEGIN


virkEgenskaber1 :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          'd71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;


virkEgenskaber2 :=	ROW (
	'[2014-05-12, 2015-05-12)' :: TSTZRANGE,
          'e71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx11'
          ) :: Virkning
;


virkAnsvarlig :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          'f71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkBesvarelser1 :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          'c71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkBesvarelser2 :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          'b71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;

virkFremdrift := ROW (
	'[2015-05-18, infinity)' :: TSTZRANGE,
          'a71cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx10'
) :: Virkning
;

dokumentRelAnsvarlig := ROW (
	'ansvarlig'::dokumentRelationKode,
		virkAnsvarlig,
	uuidAnsvarlig,
	null,
	'Aktør'
) :: dokumentRelationType
;


dokumentRelBesvarelser1 := ROW (
	'besvarelser'::dokumentRelationKode,
		virkBesvarelser1,
	uuidBesvarelser1,
	null,
	null
) :: dokumentRelationType
;



dokumentRelBesvarelser2 := ROW (
	'besvarelser'::dokumentRelationKode,
		virkBesvarelser2,
	null,
	urnBesvarelser2,
	null
) :: dokumentRelationType
;


dokumentFremdrift := ROW (
virkFremdrift,
'Underreview'
):: dokumentFremdriftTilsType
;


dokumentEgenskab1 := ROW (
'doc_brugervendtnoegle1',
'doc_beskrivelse1', 
'10-31-2015'::date,
'doc_kassationskode1', 
4, --major int
9, --minor int
ROW('doc_Offentlighedundtaget_AlternativTitel1','doc_Offentlighedundtaget_Hjemmel1') ::OffentlighedundtagetType, --offentlighedundtagettype,
'doc_titel1',
'doc_dokumenttype1',
   virkEgenskaber1
) :: dokumentEgenskaberAttrType
;

dokumentEgenskab2 := ROW (
'doc_brugervendtnoegle2',
'doc_beskrivelse2', 
'09-20-2014'::date,
'doc_kassationskode2', 
5, --major int
10, --minor int
ROW('doc_Offentlighedundtaget_AlternativTitel2','doc_Offentlighedundtaget_Hjemmel2') ::OffentlighedundtagetType, --offentlighedundtagettype,
'doc_titel2',
'doc_dokumenttype2',
   virkEgenskaber2
) :: dokumentEgenskaberAttrType
;




docDel2Brelation2Virkning :=	ROW (
	'(2011-08-24, 2015-10-01]' :: TSTZRANGE,
          '971cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx70'
          ) :: Virkning
;

docDel2Brelation1Virkning :=	ROW (
	'[2012-05-08, infinity)' :: TSTZRANGE,
          '871cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx70'
          ) :: Virkning
;


docDel1Arelation1Virkning :=	ROW (
	'[2014-05-10, infinity)' :: TSTZRANGE,
          '771cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx71'
          ) :: Virkning
;


docVariantEgenskaber2AVirkning :=	ROW (
	'[2014-07-12, infinity)' :: TSTZRANGE,
          '671cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx281'
          ) :: Virkning
;

docVariantEgenskaber1BVirkning :=	ROW (
	'[2014-06-11, infinity)' :: TSTZRANGE,
          '571cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx291'
          ) :: Virkning
;


docVariantEgenskaber1AVirkning :=	ROW (
	'[2013-02-27, 2014-06-11)' :: TSTZRANGE,
          '471cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx191'
          ) :: Virkning
;

docDel1AEgenskaberVirkning :=	ROW (
	'[2014-03-30, infinity)' :: TSTZRANGE,
          '371cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx11'
          ) :: Virkning
;

docDel1A2EgenskaberVirkning :=	ROW (
	'[2010-01-20, 2014-03-20)' :: TSTZRANGE,
          '271cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx113'
          ) :: Virkning
;


docDel1BEgenskaberVirkning :=	ROW (
	'[2015-10-11, infinity)' :: TSTZRANGE,
          '171cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx12'
          ) :: Virkning
;

docDel2AEgenskaberVirkning :=	ROW (
	'[2013-02-28, infinity)' :: TSTZRANGE,
          '901cc58a-3149-414a-9392-dcbcbbccddf8'::uuid,
          'Bruger',
          'NoteEx13'
          ) :: Virkning
;


docVariantEgenskaber1A:=
ROW(
true, --arkivering boolean, 
false, --delvisscannet boolean, 
true, --offentliggoerelse boolean, 
false, --produktion boolean,
 docVariantEgenskaber1AVirkning
)::DokumentVariantEgenskaberType;

docVariantEgenskaber1B:=
ROW(
false, --arkivering boolean, 
false, --delvisscannet boolean, 
true, --offentliggoerelse boolean, 
true, --produktion boolean,
 docVariantEgenskaber1BVirkning
)::DokumentVariantEgenskaberType;


docVariantEgenskaber2A:=
ROW(
false, --arkivering boolean, 
true, --delvisscannet boolean, 
false, --offentliggoerelse boolean, 
true, --produktion boolean,
 docVariantEgenskaber2AVirkning
)::DokumentVariantEgenskaberType;


docDel2Brelation1:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  docDel2Brelation1Virkning,
  'a24a2dd4-415f-4104-b7a7-84607488c096'::uuid,
  null, --relMaalUrn,
  'Bruger'
)::DokumentdelRelationType;


docDel2Brelation2:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  docDel2Brelation2Virkning,
  null,
  'urn:cpr 8883394', 
  'Bruger'
)::DokumentdelRelationType;


docDel1Arelation1:=
ROW (
  'underredigeringaf'::DokumentdelRelationKode,
  docDel2Brelation2Virkning,
  'b24a2dd4-415f-4104-b7a7-84607488c091'::uuid,
  null, 
  'Bruger'
)::DokumentdelRelationType;


docDel1AEgenskaber:= ROW(
1, --indeks int,
'del_indhold1', 
'del_lokation1', 
'del_mimetype1',
 docDel1AEgenskaberVirkning 
)::DokumentDelEgenskaberType
;

docDel1A2Egenskaber:=ROW(
2, --indeks int,
'del_indhold4', 
'del_lokation4', 
'del_mimetype4',
 docDel1A2EgenskaberVirkning 
)::DokumentDelEgenskaberType
;

docDel1BEgenskaber:= ROW(
98, --indeks int,
'del_indhold2', 
'del_lokation2', 
'del_mimetype2',
 docDel1BEgenskaberVirkning 
)::DokumentDelEgenskaberType
;

docDel2AEgenskaber:= ROW(
8, --indeks int,
'del_indhold3', 
'del_lokation3', 
'del_mimetype3',
 docDel2AEgenskaberVirkning 
)::DokumentDelEgenskaberType
;


docDel1A:=
ROW(
'doc_deltekst1A',
  ARRAY[docDel1AEgenskaber,docDel1A2Egenskaber],
  ARRAY[docDel1Arelation1]
)::DokumentDelType;

docDel1B:=
ROW(
'doc_deltekst1B',
  ARRAY[docDel1BEgenskaber],
  ARRAY[]::DokumentdelRelationType[]
)::DokumentDelType;

docDel2A:=
ROW(
'doc_deltekst2A',
  ARRAY[docDel2AEgenskaber],
  ARRAY[]::DokumentdelRelationType[]
)::DokumentDelType;

docDel2B:=
ROW(
'doc_deltekst2B',
  ARRAY[]::DokumentDelEgenskaberType[],
  ARRAY[docDel2Brelation1,docDel2Brelation2]
)::DokumentDelType;


docVariant1 := ROW (
	'doc_varianttekst1',
  	ARRAY[docVariantEgenskaber1A,docVariantEgenskaber1B],
  	ARRAY[docDel1A,docDel1B]
)::DokumentVariantType;


docVariant2 := ROW (
	'doc_varianttekst2',
  ARRAY[docVariantEgenskaber2A],
  ARRAY[docDel2A,docDel2B]
)::DokumentVariantType;

registrering := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistrering,
	'Test Note 85') :: RegistreringBase
	,
ARRAY[dokumentFremdrift]::dokumentFremdriftTilsType[],
ARRAY[dokumentEgenskab1,dokumentEgenskab2]::dokumentEgenskaberAttrType[],
ARRAY[dokumentRelAnsvarlig,dokumentRelBesvarelser1,dokumentRelBesvarelser2],
ARRAY[docVariant1,docVariant2]
) :: dokumentRegistreringType
;


new_uuid := as_create_or_import_dokument(registrering);

RETURN NEXT is(
	ARRAY(
		SELECT
			id
		FROM
		dokument
		where id=new_uuid
		),
	ARRAY[new_uuid]::uuid[]
);


SELECT
	(a.registrering).* into actual_registrering
FROM
dokument_registrering a
where dokument_id=new_uuid
;


RETURN NEXT is(actual_registrering.livscykluskode,(registrering.registrering).livscykluskode,'registrering livscykluskode');
RETURN NEXT is(actual_registrering.brugerref,(registrering.registrering).brugerref,'registrering brugerref');
RETURN NEXT is(actual_registrering.note,(registrering.registrering).note,'registrering note');
RETURN NEXT ok(upper(actual_registrering.timeperiod)='infinity'::timestamp with time zone,'registrering timeperiod upper is infinity');
RETURN NEXT ok(lower(actual_registrering.timeperiod) <clock_timestamp(),'registrering timeperiod before now');
RETURN NEXT ok(lower(actual_registrering.timeperiod) > clock_timestamp() - 3 * interval '1 second',' registrering timeperiod later than 3 secs' );

SELECT
	 	(a.virkning).* into actual_fremdrift_virk
FROM dokument_tils_fremdrift a 
JOIN dokument_registrering as b on a.dokument_registrering_id=b.id
WHERE b.dokument_id=new_uuid
;

SELECT
	 	a.fremdrift into actual_fremdrift_value
FROM dokument_tils_fremdrift a 
JOIN dokument_registrering as b on a.dokument_registrering_id=b.id
WHERE b.dokument_id=new_uuid
;

actual_fremdrift:=ROW(
	actual_fremdrift_virk,
	actual_fremdrift_value
)::dokumentFremdriftTilsType ;


RETURN NEXT is(actual_fremdrift.virkning,dokumentFremdrift.virkning,'fremdrift virkning');
RETURN NEXT is(actual_fremdrift.fremdrift,dokumentFremdrift.fremdrift,'fremdrift value');

SELECT
array_agg(
			ROW (
					a.rel_type,
					a.virkning,
					a.rel_maal_uuid,
					a.rel_maal_urn,
					a.objekt_type 
				):: dokumentRelationType
		) into actual_relationer
FROM dokument_relation a
JOIN dokument_registrering as b on a.dokument_registrering_id=b.id
WHERE b.dokument_id=new_uuid
;

RETURN NEXT is(
	actual_relationer,
	ARRAY[dokumentRelAnsvarlig,dokumentRelBesvarelser1,dokumentRelBesvarelser2]
,'relations present');

SELECT array_agg(
	ROW(
		a.brugervendtnoegle,
		a.beskrivelse, 
		a.brevdato,
		a.kassationskode, 
		a.major, 
		a.minor, 
		a.offentlighedundtaget,
		a.titel,
		a.dokumenttype,
 		a.virkning
 )::dokumentEgenskaberAttrType
	order by a.major ASC
) into actual_egenskaber
from dokument_attr_egenskaber a
JOIN dokument_registrering as b on a.dokument_registrering_id=b.id
WHERE b.dokument_id=new_uuid
;


RETURN NEXT is(
	actual_egenskaber,
	ARRAY[dokumentEgenskab1,dokumentEgenskab2]
,'egenskaber present');


--****************************
--test an import operation
uuid_returned_from_import:=as_create_or_import_dokument(registrering,uuid_to_import);

RETURN NEXT is(
	uuid_returned_from_import,
	uuid_to_import,
	'import returns uuid'
	);

RETURN NEXT is(
	ARRAY(
		SELECT
			id
		FROM
		dokument
		where id=uuid_to_import
		),
	ARRAY[uuid_to_import]::uuid[]
,'import creates new dokument.');




END;
$$;