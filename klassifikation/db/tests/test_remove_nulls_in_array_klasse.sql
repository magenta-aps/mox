-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_remove_nulls_in_array_klasse()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
relationerArr	KlasseRelationType[];
relationerArr2	KlasseRelationType[];
relationerArr3	KlasseRelationType[];
relationerArr4	KlasseRelationType[];
egenskaberArr	KlasseEgenskaberAttrType[];
soegeordArr	KlasseSoegeordType[];
publiceretArr	KlassePubliceretTilsType[];
resultRelationerArr	KlasseRelationType[];
resultRelationerArr2	KlasseRelationType[];
resultRelationerArr3	KlasseRelationType[];
resultRelationerArr4	KlasseRelationType[];
resultRelationerArr5	KlasseRelationType[];
tempKlasseRel			KlasseRelationType;
BEGIN

relationerArr:=array_append(relationerArr,
 ROW (
	'ansvarlig'::KlasseRelationKode,
		ROW (
	'[2015-05-11, infinity)' :: TSTZRANGE,
          'b0ba2a98-2c2e-4628-b030-e39e25c8166a'::uuid,
          'Bruger',
          'NoteEx2'
          ) :: Virkning,
	  'cbe8142b-bafc-4aaf-89b6-4e90b9e08907'::uuid
) :: KlasseRelationType
)
;

relationerArr:=array_append(relationerArr,
 ROW (
	'ansvarlig'::KlasseRelationKode,
		ROW (
	'[2015-05-14, infinity)' :: TSTZRANGE,
          'b0ba2a98-2c2e-4628-b030-e39e25c8166a'::uuid,
          'Bruger',
          'NoteEx3'
          ) :: Virkning,
	  'fbe8142b-bafc-4aaf-89b6-4e90b9e08908'::uuid
) :: KlasseRelationType
)
;

relationerArr:=array_append(relationerArr,
 ROW (
	'ansvarlig'::KlasseRelationKode,
		ROW (
	'[2015-05-19, infinity)' :: TSTZRANGE,
          'c0ba2a98-2c2e-4628-b030-e39e25c81664'::uuid,
          'Bruger',
          'NoteEx10'
          ) :: Virkning,
	  'ebe8142b-bafc-4aaf-89b6-4e90b9e08909'::uuid
) :: KlasseRelationType
)
;

relationerArr:=array_append(relationerArr,
 ROW (
	'ansvarlig'::KlasseRelationKode,
		ROW (
	'[2015-05-13, infinity)' :: TSTZRANGE,
          'd0ba2a98-2c2e-4628-b030-e39e25c81662'::uuid,
          'Bruger',
          'NoteEx11'
          ) :: Virkning,
	  'cee8142b-bafc-4aaf-89b6-4e90b9e08900'::uuid
) :: KlasseRelationType
)
;

relationerArr:=array_append(relationerArr,
 ROW (
	'ansvarlig'::KlasseRelationKode,
		ROW (
	'[2015-04-13, infinity)' :: TSTZRANGE,
          '30ba2a98-2c2e-4628-b030-e39e25c81669'::uuid,
          'Bruger',
          'NoteEx30'
          ) :: Virkning,
	  '3ee8142b-bafc-4aaf-89b6-4e90b9e08908'::uuid
) :: KlasseRelationType
)
;



IF NOT coalesce(array_length(relationerArr,1),0)=5 THEN
	RAISE EXCEPTION 'Test assumption 1 failed.';
END IF;

resultRelationerArr:=_remove_nulls_in_array(relationerArr);

RETURN NEXT is(relationerArr,resultRelationerArr,'Test if non null elements and order is preserved');


relationerArr2:=array_append(relationerArr,null);
relationerArr2:=array_append(relationerArr2,null);
relationerArr2:=array_prepend(null,relationerArr2);
relationerArr2:=array_prepend(null,relationerArr2);

IF NOT coalesce(array_length(relationerArr2,1),0)=9 THEN
	RAISE EXCEPTION 'Test assumption 2 failed.';
END IF;

resultRelationerArr2:=_remove_nulls_in_array(relationerArr2);

RETURN NEXT is(resultRelationerArr2,relationerArr,'Test if null values are removed');

relationerArr3:=array_append(relationerArr,
	 ROW (
		null--'ansvarlig'::KlasseRelationKode,
		,null	/*ROW (
		'[2015-04-13, infinity)' :: TSTZRANGE,
	          '30ba2a98-2c2e-4628-b030-e39e25c81669'::uuid,
	          'Bruger',
	          'NoteEx30'
	          ) :: Virkning,*/
		,null--  '3ee8142b-bafc-4aaf-89b6-4e90b9e08908'::uuid
	) :: KlasseRelationType	
);

IF NOT coalesce(array_length(relationerArr3,1),0)=6 THEN
	RAISE EXCEPTION 'Test assumption 3 failed.';
END IF;

resultRelationerArr3:=_remove_nulls_in_array(relationerArr3);

RETURN NEXT is(resultRelationerArr3,relationerArr,'Test if element with only null values are removed');

resultRelationerArr4:='{}'::KlasseRelationType[];

RETURN NEXT is(_remove_nulls_in_array(resultRelationerArr4),null,'Test that empty arrays, gets converted to null');

resultRelationerArr5:=null;

RETURN NEXT is(_remove_nulls_in_array(resultRelationerArr5),null,'Test that null arrays stays null');

--TODO: Added similar tests for the other types

END;
$$;