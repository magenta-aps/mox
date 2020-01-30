-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_search_itsystem()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
	new_uuidA uuid;
	new_uuidB uuid;
	new_uuidC uuid;
	new_uuidD uuid;
	registreringA ItsystemRegistreringType;
	registreringB ItsystemRegistreringType;
	registreringC ItsystemRegistreringType;
	registreringD ItsystemRegistreringType;
	actual_registrering RegistreringBase;
	virkEgenskaberA Virkning;
	virkAnsvarligA Virkning;
	virkOrganisationer1A Virkning;
	virkOrganisationer2A Virkning;
	virkGyldighedA Virkning;
	itsystemEgenskabA ItsystemEgenskaberAttrType;
	itsystemEgenskabB ItsystemEgenskaberAttrType;
	itsystemEgenskabC ItsystemEgenskaberAttrType;
	itsystemEgenskabD ItsystemEgenskaberAttrType;
	itsystemGyldighedA ItsystemGyldighedTilsType;
	itsystemRelAnsvarligA ItsystemRelationType;
	itsystemRelOrganisationer1A ItsystemRelationType;
	itsystemRelOrganisationer2A ItsystemRelationType;
	uuidAnsvarligA uuid :='be61544e-985f-4559-ac64-7034ae889d53'::uuid;
	uuidOrganisationer1A uuid :='981fe680-3881-4331-a64e-92fc253c687b'::uuid;
	uuidOrganisationer2A uuid :='0b1944e6-4c49-4a24-bf1b-bceef3b6f00f'::uuid;
	uuidRegistreringA uuid :='8076ac04-8099-4d0c-ba78-56d0c577023a'::uuid;
	search_result1 uuid[];
	search_result2 uuid[];
	search_result3 uuid[];
	search_result4 uuid[];
	search_result5 uuid[];
	expected_result2 uuid[];
	expected_result3 uuid[];
	expected_result4 uuid[];
	expected_result5 uuid[];
BEGIN
--ItsystemGyldighedTils AS ENUM ('Aktiv','Inaktiv','');


virkEgenskaberA :=	ROW (
	'[2015-05-12, infinity)' :: TSTZRANGE,
          'ce61544e-985f-4559-ac64-7034ae889d53'::uuid,
          'Bruger',
          'NoteEx1'
          ) :: Virkning
;

virkAnsvarligA :=	ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          'ae61544e-985f-4559-ac64-7034ae889d54'::uuid,
          'Bruger',
          'NoteEx2'
          ) :: Virkning
;

virkOrganisationer1A :=	ROW (
	'[2015-05-10, infinity)' :: TSTZRANGE,
          'de61544e-985f-4559-ac64-7034ae889d51'::uuid,
          'Bruger',
          'NoteEx3'
          ) :: Virkning
;


virkOrganisationer2A :=	ROW (
	'[2015-05-10, 2016-05-10)' :: TSTZRANGE,
          'ee61544e-985f-4559-ac64-7034ae889d52'::uuid,
          'Bruger',
          'NoteEx4'
          ) :: Virkning
;

virkGyldighedA := ROW (
	'[2015-05-18, infinity)' :: TSTZRANGE,
          'be61544e-985f-4559-ac64-7034ae889d54'::uuid,
          'Bruger',
          'NoteEx10'
) :: Virkning
;

itsystemRelAnsvarligA := ROW (
	'tilhoerer'::ItsystemRelationKode,
		virkAnsvarligA,
	uuidAnsvarligA,
	null,
	null
) :: ItsystemRelationType
;


itsystemRelOrganisationer1A := ROW (
	'tilknyttedeorganisationer'::ItsystemRelationKode,
		virkOrganisationer1A,
	uuidOrganisationer1A,
	null,
	null
) :: ItsystemRelationType
;



itsystemRelOrganisationer2A := ROW (
	'tilknyttedeorganisationer'::ItsystemRelationKode,
		virkOrganisationer2A,
	uuidOrganisationer2A,
	null,
	null
) :: ItsystemRelationType
;


itsystemGyldighedA := ROW (
virkGyldighedA,
'Inaktiv'::ItsystemGyldighedTils
):: ItsystemGyldighedTilsType
;




itsystemEgenskabA := ROW (
'brugervendt_noegle_text1',
   'itsystemnavn_text1',
   'itsystemtype_text1',
   ARRAY['konfigurationreference_text1','konfigurationreference_text2','konfigurationreference_text3']::text[],
   'integrationsdata_text1',
   virkEgenskaberA
) :: ItsystemEgenskaberAttrType
;

itsystemEgenskabB := ROW (
'brugervendt_noegle_text1',
   'itsystemnavn_text1',
   'itsystemtype_text1',
   ARRAY['konfigurationreference_text1B','konfigurationreference_text2B','konfigurationreference_text3B']::text[],
   'integrationsdata_text1',
   virkEgenskaberA
) :: ItsystemEgenskaberAttrType
;

itsystemEgenskabC := ROW (
'brugervendt_noegle_text1',
   'itsystemnavn_text1',
   'itsystemtype_text1',
   ARRAY['konfigurationreference_text1C','konfigurationreference_text2C','konfigurationreference_text3C']::text[],
   'integrationsdata_text1',
   virkEgenskaberA
) :: ItsystemEgenskaberAttrType
;

itsystemEgenskabD := ROW (
'brugervendt_noegle_text1',
   'itsystemnavn_text1',
   'itsystemtype_text1',
   ARRAY[]::text[],
   'integrationsdata_text1',
   virkEgenskaberA
) :: ItsystemEgenskaberAttrType
;

registreringA := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistreringA,
	'Test Note 4') :: RegistreringBase
	,
ARRAY[itsystemGyldighedA]::ItsystemGyldighedTilsType[],
ARRAY[itsystemEgenskabA]::ItsystemEgenskaberAttrType[],
ARRAY[itsystemRelAnsvarligA,itsystemRelOrganisationer1A,itsystemRelOrganisationer2A]
) :: ItsystemRegistreringType
;

registreringB := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistreringA,
	'Test Note 5') :: RegistreringBase
	,
ARRAY[itsystemGyldighedA]::ItsystemGyldighedTilsType[],
ARRAY[itsystemEgenskabB]::ItsystemEgenskaberAttrType[],
ARRAY[itsystemRelAnsvarligA,itsystemRelOrganisationer1A,itsystemRelOrganisationer2A]
) :: ItsystemRegistreringType
;

registreringC := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistreringA,
	'Test Note 5') :: RegistreringBase
	,
ARRAY[itsystemGyldighedA]::ItsystemGyldighedTilsType[],
ARRAY[itsystemEgenskabC]::ItsystemEgenskaberAttrType[],
ARRAY[itsystemRelAnsvarligA,itsystemRelOrganisationer1A,itsystemRelOrganisationer2A]
) :: ItsystemRegistreringType
;


registreringD := ROW (

	ROW (
	NULL,
	'Opstaaet'::Livscykluskode,
	uuidRegistreringA,
	'Test Note 5') :: RegistreringBase
	,
ARRAY[itsystemGyldighedA]::ItsystemGyldighedTilsType[],
ARRAY[itsystemEgenskabD]::ItsystemEgenskaberAttrType[], 
ARRAY[itsystemRelAnsvarligA,itsystemRelOrganisationer1A,itsystemRelOrganisationer2A]
) :: ItsystemRegistreringType
;

new_uuidA := as_create_or_import_itsystem(registreringA);
new_uuidB := as_create_or_import_itsystem(registreringB);
new_uuidC := as_create_or_import_itsystem(registreringC);
new_uuidD := as_create_or_import_itsystem(registreringD);


search_result1 :=as_search_itsystem(
	null,--TOOD ??
	null,
	ROW(
		null,
		null, --ARRAY[itsystemGyldighed]::ItsystemGyldighedTilsType[]
		ARRAY[
		ROW('brugervendt_noegle_text1',
   			'itsystemnavn_text1',
   			'itsystemtype_text1',
   			ARRAY['konfigurationreference_text1C']::text[],
   			'integrationsdata_text1',
   			virkEgenskaberA) ::ItsystemEgenskaberAttrType
		]::ItsystemEgenskaberAttrType[],
		null
		)::ItsystemRegistreringType,
	null,--registrering_A Facetregistrering_AType
	null--virkningSoeg
	);

RETURN NEXT is(
search_result1,
ARRAY[new_uuidC]::uuid[],
'simple search on a single konfigurationreference'
);

---------------------------------------------------

search_result2 :=as_search_itsystem(
	null,--TOOD ??
	null,
	ROW(
		null,
		null, --ARRAY[itsystemGyldighed]::ItsystemGyldighedTilsType[]
		ARRAY[
		ROW('brugervendt_noegle_text1',
   			'itsystemnavn_text1',
   			'itsystemtype_text1',
   			ARRAY['konfigurationreference_text%']::text[],
   			'integrationsdata_text1',
   			virkEgenskaberA) ::ItsystemEgenskaberAttrType
		]::ItsystemEgenskaberAttrType[],
		null
		)::ItsystemRegistreringType,
	null,--registrering_A Facetregistrering_AType
	null--virkningSoeg
	);

expected_result2:=ARRAY[new_uuidA,new_uuidB,new_uuidC]::uuid[];


RETURN NEXT ok(expected_result2 @> search_result2 and search_result2 @>expected_result2 and array_length(expected_result2,1)=array_length(search_result2,1), 'wildcard search on a single konfigurationreference');
---------------------------------------------------

search_result3 :=as_search_itsystem(
	null,--TOOD ??
	null,
	ROW(
		null,
		null, --ARRAY[itsystemGyldighed]::ItsystemGyldighedTilsType[]
		ARRAY[
		ROW('brugervendt_noegle_text1',
   			'itsystemnavn_text1',
   			'itsystemtype_text1',
   			ARRAY['konfigurationreference_text%','konfigurationreference_text2B']::text[],
   			'integrationsdata_text1',
   			virkEgenskaberA) ::ItsystemEgenskaberAttrType
		]::ItsystemEgenskaberAttrType[],
		null
		)::ItsystemRegistreringType,
	null,--registrering_A Facetregistrering_AType
	null--virkningSoeg
	);

expected_result3:=ARRAY[new_uuidB]::uuid[];


RETURN NEXT ok(expected_result3 @> search_result3 and search_result3 @>expected_result3 and array_length(expected_result3,1)=array_length(search_result3,1), 'wildcard search on 2 konfigurationreferencer, one with wildcard');
---------------------------------------------------

search_result4 :=as_search_itsystem(
	null,--TOOD ??
	null,
	ROW(
		null,
		null, --ARRAY[itsystemGyldighed]::ItsystemGyldighedTilsType[]
		ARRAY[
		ROW('brugervendt_noegle_text1',
   			'itsystemnavn_text1',
   			'itsystemtype_text1',
   			ARRAY[]::text[],
   			'integrationsdata_text1',
   			virkEgenskaberA) ::ItsystemEgenskaberAttrType
		]::ItsystemEgenskaberAttrType[],
		null
		)::ItsystemRegistreringType,
	null,--registrering_A Facetregistrering_AType
	null--virkningSoeg
	);

expected_result4:=ARRAY[new_uuidD]::uuid[];


RETURN NEXT ok(expected_result4 @> search_result4 and search_result4 @>expected_result4 and coalesce(array_length(expected_result4,1),0)=coalesce(array_length(search_result4,1),0), 'search on explicit empty array konfigurationreference');
---------------------------------------------------




END;
$$;
