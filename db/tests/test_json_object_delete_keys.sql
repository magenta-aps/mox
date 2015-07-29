-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_json_object_delete_keys()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
sagRelType1 SagRelationType;	
resultJson json;
actualCount1 int;
actualCount2 int;
BEGIN

sagRelType1 := ROW (
	'ansvarlig'::sagRelationKode
	,null --virkning
	,'f7109356-e87e-4b10-ad5d-36de6e3ee09f'::uuid
	,null --relmaalurn
	,'Klasse' --objekttype
	,567   --relIndex
	,null --relTypeSpec
	,null --journalNotat
	,null --journalDokumentAttr
) :: SagRelationType
;

resultJson:=_json_object_delete_keys(row_to_json(sagRelType1),ARRAY['reltypespec','journalnotat','journaldokumentattr']);
select count(*) into actualCount1 from json_each(resultJson);
select count(*) into actualCount2 from json_each(resultJson) where key = ANY(ARRAY['reltypespec','journalnotat','journaldokumentattr','relmaalurn']) ;
return next is(actualCount1,6,'Test for number of json fields, after delete #1.');
return next is(actualCount2,1,'Test for number of json fields, after delete #2.');





END;
$$;
