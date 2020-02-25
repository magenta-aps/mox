-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_remove_nulls_in_array_klasse()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 

relationerArr	KlasseRelationType[];
relationerArr2	KlasseRelationType[];
relationerArr3	KlasseRelationType[];
relationerArr4	KlasseRelationType[];
resultRelationerArr	KlasseRelationType[];
resultRelationerArr2	KlasseRelationType[];
resultRelationerArr3	KlasseRelationType[];
resultRelationerArr4	KlasseRelationType[];
resultRelationerArr5	KlasseRelationType[];
publiceretArr	KlassePubliceretTilsType[];
publiceretArr2	KlassePubliceretTilsType[];
publiceretArr3	KlassePubliceretTilsType[];
publiceretArr4	KlassePubliceretTilsType[];
resultpubliceretArr	KlassePubliceretTilsType[];
resultpubliceretArr2	KlassePubliceretTilsType[];
resultpubliceretArr3	KlassePubliceretTilsType[];
resultpubliceretArr4	KlassePubliceretTilsType[];
resultpubliceretArr5	KlassePubliceretTilsType[];
egenskaberArr	KlasseegenskaberAttrType[];
egenskaberArr2	KlasseegenskaberAttrType[];
egenskaberArr3	KlasseegenskaberAttrType[];
egenskaberArr4	KlasseegenskaberAttrType[];
resultegenskaberArr	KlasseegenskaberAttrType[];
resultegenskaberArr2	KlasseegenskaberAttrType[];
resultegenskaberArr3	KlasseegenskaberAttrType[];
resultegenskaberArr4	KlasseegenskaberAttrType[];
resultegenskaberArr5	KlasseegenskaberAttrType[];
soegeordArr	KlasseSoegeordType[];
soegeordArr2	KlasseSoegeordType[];
soegeordArr3	KlasseSoegeordType[];
soegeordArr4	KlasseSoegeordType[];
resultsoegeordArr	KlasseSoegeordType[];
resultsoegeordArr2	KlasseSoegeordType[];
resultsoegeordArr3	KlasseSoegeordType[];
resultsoegeordArr4	KlasseSoegeordType[];
resultsoegeordArr5	KlasseSoegeordType[];

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
	  'cbe8142b-bafc-4aaf-89b6-4e90b9e08907'::uuid,
	  null,
	  null
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
	  'fbe8142b-bafc-4aaf-89b6-4e90b9e08908'::uuid,
	  null,
	  null
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
	  'ebe8142b-bafc-4aaf-89b6-4e90b9e08909'::uuid,
	  null,
	  null
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
	  'cee8142b-bafc-4aaf-89b6-4e90b9e08900'::uuid,
	  null,
	  null
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
	  '3ee8142b-bafc-4aaf-89b6-4e90b9e08908'::uuid,
	  null,
	  null
) :: KlasseRelationType
)
;



IF NOT coalesce(array_length(relationerArr,1),0)=5 THEN
	RAISE EXCEPTION 'Test assumption 1 failed. #relationer';
END IF;

resultRelationerArr:=_remove_nulls_in_array(relationerArr);

RETURN NEXT is(relationerArr,resultRelationerArr,'Test if non null elements and order is preserved #relationer');


relationerArr2:=array_append(relationerArr,null);
relationerArr2:=array_append(relationerArr2,null);
relationerArr2:=array_prepend(null,relationerArr2);
relationerArr2:=array_prepend(null,relationerArr2);

IF NOT coalesce(array_length(relationerArr2,1),0)=9 THEN
	RAISE EXCEPTION 'Test assumption 2 failed. #relationer';
END IF;

resultRelationerArr2:=_remove_nulls_in_array(relationerArr2);

RETURN NEXT is(resultRelationerArr2,relationerArr,'Test if null values are removed #relationer');

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
		,null
		,null
	) :: KlasseRelationType	
);

IF NOT coalesce(array_length(relationerArr3,1),0)=6 THEN
	RAISE EXCEPTION 'Test assumption 3 failed.';
END IF;

resultRelationerArr3:=_remove_nulls_in_array(relationerArr3);

RETURN NEXT is(resultRelationerArr3,relationerArr,'Test if element with only null values are removed #relationer');

resultRelationerArr4:='{}'::KlasseRelationType[];

RETURN NEXT is(_remove_nulls_in_array(resultRelationerArr4),null,'Test that empty arrays, gets converted to null #relationer');

resultRelationerArr5:=null;

RETURN NEXT is(_remove_nulls_in_array(resultRelationerArr5),null,'Test that null arrays stays null #relationer');


------------------------------------------------------------


publiceretArr:=array_append(publiceretArr,
ROW(
	ROW (
	'[2015-04-13, infinity)' :: TSTZRANGE,
          '30ba2a98-2c2e-4628-b030-e39e25c81669'::uuid,
          'Bruger',
          'NoteEx30'
          ) :: Virkning,
'Publiceret'
):: klassePubliceretTilsType
);

publiceretArr:=array_append(publiceretArr,
ROW(
	ROW (
	'[2014-04-13, infinity)' :: TSTZRANGE,
          '50ba2a98-2c2e-4628-b030-e39e25c81669'::uuid,
          'Bruger',
          'NoteEx40'
          ) :: Virkning,
'IkkePubliceret'
):: klassePubliceretTilsType
);


publiceretArr:=array_append(publiceretArr,
ROW(
	ROW (
	'[2014-05-13, infinity)' :: TSTZRANGE,
          '30ba2a98-2c2e-4628-b030-e39e25c81669'::uuid,
          'Bruger',
          'NoteEx50'
          ) :: Virkning,
''
):: klassePubliceretTilsType
);

publiceretArr:=array_append(publiceretArr,
ROW(
	ROW (
	'[2014-05-13, infinity)' :: TSTZRANGE,
          '60ba2a98-2c2e-4628-b030-e39e25c81669'::uuid,
          'Bruger',
          'NoteEx60'
          ) :: Virkning,
'Publiceret'
):: klassePubliceretTilsType
);



IF NOT coalesce(array_length(publiceretArr,1),0)=4 THEN
	RAISE EXCEPTION 'Test publiceret assumption 1 failed. # publiceret';
END IF;

resultpubliceretArr:=_remove_nulls_in_array(publiceretArr);

RETURN NEXT is(publiceretArr,resultpubliceretArr,'Test if non null elements and order is preserved # publiceret');


publiceretArr2:=array_append(publiceretArr,null);
publiceretArr2:=array_append(publiceretArr2,null);
publiceretArr2:=array_prepend(null,publiceretArr2);
publiceretArr2:=array_prepend(null,publiceretArr2);

IF NOT coalesce(array_length(publiceretArr2,1),0)=8 THEN
	RAISE EXCEPTION 'Test publiceret assumption 2 failed. # publiceret';
END IF;

resultpubliceretArr2:=_remove_nulls_in_array(publiceretArr2);

RETURN NEXT is(resultpubliceretArr2,publiceretArr,'Test if null values are removed # publiceret');

publiceretArr3:=array_append(publiceretArr,
	 ROW (
		null
		,null	
	) :: KlassePubliceretTilsType
);

IF NOT coalesce(array_length(publiceretArr3,1),0)=5 THEN
	RAISE EXCEPTION 'Test assumption 3 failed. # publiceret';
END IF;

resultpubliceretArr3:=_remove_nulls_in_array(publiceretArr3);

RETURN NEXT is(resultpubliceretArr3,publiceretArr,'Test if element with only null values are removed # publiceret');

resultpubliceretArr4:='{}'::KlassePubliceretTilsType[];

RETURN NEXT is(_remove_nulls_in_array(resultpubliceretArr4),null,'Test that empty arrays, gets converted to null # publiceret');

resultpubliceretArr5:=null;

RETURN NEXT is(_remove_nulls_in_array(resultpubliceretArr5),null,'Test that null arrays stays null # publiceret');

------------------------------------------------------------


egenskaberArr:=array_append(egenskaberArr,
ROW(
	'brugervendt_noegle_E',
   'klassebeskrivelse_E',
   'eksempel_E',
	'omfang_E',
   'titel_E',
   'retskilde_E',
   'aendringsnotat', 
   'integrationsdata_E', 
    ARRAY[ROW('soegeordidentifikator_klasseEgenskabE_Soegeord1','beskrivelse_klasseEgenskabE_Soegeord1','soegeordskategori_klasseEgenskabE_Soegeord1')::KlasseSoegeordType]
	,ROW ('[2015-04-13, infinity)' :: TSTZRANGE,'30ba2a98-2c2e-4628-b030-e39e25c81669'::uuid,'Bruger','NoteEx30') :: Virkning
):: KlasseEgenskaberAttrType
);


egenskaberArr:=array_append(egenskaberArr,
ROW(
	'brugervendt_noegle_A',
   'klassebeskrivelse_A',
   'eksempel_A',
	'omfang_A',
   'titel_A',
   'retskilde_A',
   'aendringsnotat_A', 
   'integrationsdata_A', 
    ARRAY[ROW('soegeordidentifikator_klasseEgenskabA_Soegeord1','beskrivelse_klasseEgenskabA_Soegeord1','soegeordskategori_klasseEgenskabA_Soegeord1')::KlasseSoegeordType]
	,ROW ('[2015-04-12, infinity)' :: TSTZRANGE,'50ba2a98-2c2e-4628-b030-e39e25c81669'::uuid,'Bruger','NoteEx40') :: Virkning
):: KlasseEgenskaberAttrType
);


egenskaberArr:=array_append(egenskaberArr,
ROW(
	'brugervendt_noegle_C',
   'klassebeskrivelse_C',
   'eksempel_C',
	'omfang_C',
   'titel_C',
   'retskilde_C',
   'aendringsnotat_C', 
   'integrationsdata_C', 
    ARRAY[]::KlasseSoegeordType[]
	,ROW ('[2015-04-12, infinity)' :: TSTZRANGE,'50ba2a98-2c2e-4628-b030-e39e25c81669'::uuid,'Bruger','NoteEx40') :: Virkning
):: KlasseEgenskaberAttrType
);

egenskaberArr:=array_append(egenskaberArr,
ROW(
	'brugervendt_noegle_D',
   'klassebeskrivelse_D',
   'eksempel_D',
	'omfang_D',
   'titel_D',
   'retskilde_D',
   'aendringsnotat_D', 
   'integrationsdata_D', 
    ARRAY[]::KlasseSoegeordType[]
	,ROW ('[2015-04-12, infinity)' :: TSTZRANGE,'50ba2a98-2D2e-4628-b030-e39e25D81669'::uuid,'Bruger','NoteEx70') :: Virkning
):: KlasseEgenskaberAttrType
);


IF NOT coalesce(array_length(egenskaberArr,1),0)=4 THEN
	RAISE EXCEPTION 'Test egenskaber assumption 1 failed. # egenskaber';
END IF;

resultegenskaberArr:=_remove_nulls_in_array(egenskaberArr);

RETURN NEXT is(egenskaberArr,resultegenskaberArr,'Test if non null elements and order is preserved # egenskaber');


egenskaberArr2:=array_append(egenskaberArr,null);
egenskaberArr2:=array_append(egenskaberArr2,null);
egenskaberArr2:=array_prepend(null,egenskaberArr2);
egenskaberArr2:=array_prepend(null,egenskaberArr2);

IF NOT coalesce(array_length(egenskaberArr2,1),0)=8 THEN
	RAISE EXCEPTION 'Test egenskaber assumption 2 failed. # egenskaber';
END IF;

resultegenskaberArr2:=_remove_nulls_in_array(egenskaberArr2);

RETURN NEXT is(resultegenskaberArr2,egenskaberArr,'Test if null values are removed # egenskaber');

egenskaberArr3:=array_append(egenskaberArr,
	 ROW (
		null,
   null,
   null,
	null,
   null,
   null,
   null,
   null, 
    ARRAY[]::KlasseSoegeordType[]
	,null
	) :: KlasseEgenskaberAttrType
);

egenskaberArr3:=array_append(egenskaberArr3,
	 ROW (
		null,
   null,
   null,
	null,
   null,
   null,
   null, 
   null, 
    null--ARRAY[]::KlasseSoegeordType[]
	,null
	) :: KlasseEgenskaberAttrType
);

IF NOT coalesce(array_length(egenskaberArr3,1),0)=6 THEN
	RAISE EXCEPTION 'Test assumption 3 failed. # egenskaber';
END IF;

resultegenskaberArr3:=_remove_nulls_in_array(egenskaberArr3);

RETURN NEXT is(resultegenskaberArr3,egenskaberArr,'Test if element with only null values are removed # egenskaber');

resultegenskaberArr4:='{}'::KlasseegenskaberAttrType[];

RETURN NEXT is(_remove_nulls_in_array(resultegenskaberArr4),null,'Test that empty arrays, gets converted to null # egenskaber');

resultegenskaberArr5:=null;

RETURN NEXT is(_remove_nulls_in_array(resultegenskaberArr5),null,'Test that null arrays stays null # egenskaber');


------------------------------------------------------------




soegeordArr:=array_append(soegeordArr,
ROW(
'soegeordidentifikator_klasseEgenskabE_Soegeord2',
'beskrivelse_klasseEgenskabE_Soegeord2',
'soegeordskategori_klasseEgenskabE_Soegeord2'
)::KlasseSoegeordType
);


soegeordArr:=array_append(soegeordArr,
ROW(
'soegeordidentifikator_klasseEgenskabE_Soegeord1',
'beskrivelse_klasseEgenskabE_Soegeord1',
'soegeordskategori_klasseEgenskabE_Soegeord1'
)::KlasseSoegeordType
);

soegeordArr:=array_append(soegeordArr,
ROW(
'soegeordidentifikator_klasseEgenskabE_Soegeord3',
'beskrivelse_klasseEgenskabE_Soegeord3',
'soegeordskategori_klasseEgenskabE_Soegeord3'
)::KlasseSoegeordType
);

soegeordArr:=array_append(soegeordArr,
ROW(
'soegeordidentifikator_klasseEgenskabE_Soegeord5',
'beskrivelse_klasseEgenskabE_Soegeord5',
'soegeordskategori_klasseEgenskabE_Soegeord5'
)::KlasseSoegeordType
);

soegeordArr:=array_append(soegeordArr,
ROW(
'soegeordidentifikator_klasseEgenskabE_Soegeord4',
'beskrivelse_klasseEgenskabE_Soegeord4',
'soegeordskategori_klasseEgenskabE_Soegeord4'
)::KlasseSoegeordType
);
soegeordArr:=array_append(soegeordArr,
ROW(
'soegeordidentifikator_klasseEgenskabE_Soegeord6',
'beskrivelse_klasseEgenskabE_Soegeord6',
'soegeordskategori_klasseEgenskabE_Soegeord6'
)::KlasseSoegeordType
);


IF NOT coalesce(array_length(soegeordArr,1),0)=6 THEN
	RAISE EXCEPTION 'Test soegeord assumption 1 failed. # soegeord';
END IF;

resultsoegeordArr:=_remove_nulls_in_array(soegeordArr);

RETURN NEXT is(soegeordArr,resultsoegeordArr,'Test if non null elements and order is preserved # soegeord');


soegeordArr2:=array_append(soegeordArr,null);
soegeordArr2:=array_append(soegeordArr2,null);
soegeordArr2:=array_prepend(null,soegeordArr2);
soegeordArr2:=array_prepend(null,soegeordArr2);

IF NOT coalesce(array_length(soegeordArr2,1),0)=10 THEN
	RAISE EXCEPTION 'Test soegeord assumption 2 failed. # soegeord';
END IF;

resultsoegeordArr2:=_remove_nulls_in_array(soegeordArr2);

RETURN NEXT is(resultsoegeordArr2,soegeordArr,'Test if null values are removed # soegeord');

soegeordArr3:=array_append(soegeordArr,
	 ROW (
		null
		,null
		,null	
	) :: KlasseSoegeordType
);

IF NOT coalesce(array_length(soegeordArr3,1),0)=7 THEN
	RAISE EXCEPTION 'Test assumption 3 failed. # soegeord';
END IF;

resultsoegeordArr3:=_remove_nulls_in_array(soegeordArr3);

RETURN NEXT is(resultsoegeordArr3,soegeordArr,'Test if element with only null values are removed # soegeord');

resultsoegeordArr4:='{}'::KlasseSoegeordType[];

RETURN NEXT is(_remove_nulls_in_array(resultsoegeordArr4),null,'Test that empty arrays, gets converted to null # soegeord');

resultsoegeordArr5:=null;

RETURN NEXT is(_remove_nulls_in_array(resultsoegeordArr5),null,'Test that null arrays stays null # soegeord');



END;
$$;
