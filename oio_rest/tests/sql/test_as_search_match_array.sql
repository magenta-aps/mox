-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_search_match_array()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
searchForArr1 text[];
searchInArr1 text[] ;
expectedRes1 boolean;
searchForArr2 text[];
searchInArr2 text[] ;
expectedRes2 boolean;
searchForArr3 text[];
searchInArr3 text[] ;
expectedRes3 boolean;
searchForArr4 text[];
searchInArr4 text[] ;
expectedRes4 boolean;
searchForArr5 text[];
searchInArr5 text[] ;
expectedRes5 boolean;
searchForArr6 text[];
searchInArr6 text[] ;
expectedRes6 boolean;
searchForArr7 text[];
searchInArr7 text[] ;
expectedRes7 boolean;
searchForArr8 text[];
searchInArr8 text[] ;
expectedRes8 boolean;
searchForArr9 text[];
searchInArr9 text[] ;
expectedRes9 boolean;
BEGIN



expectedRes1:=true;

RETURN NEXT is(_as_search_match_array(searchForArr1,searchInArr1),expectedRes1,'search for null in null matches');

expectedRes2:=false;

searchForArr2:=ARRAY['test'];

RETURN NEXT is(_as_search_match_array(searchForArr2,searchInArr2),expectedRes2,'search for one element in null fails');


expectedRes3:=false;

searchForArr3:=ARRAY['test','test2'];

RETURN NEXT is(_as_search_match_array(searchForArr3,searchInArr3),expectedRes3,'search for 2 element in null fails');


expectedRes4:=false;

searchForArr4:=ARRAY['test','test2'];
searchInArr4:=ARRAY[]::text[];
RETURN NEXT is(_as_search_match_array(searchForArr4,searchInArr4),expectedRes4,'search for 1 element in empty* arr fails');

expectedRes5:=false;

searchForArr5:=ARRAY[]::text[];
searchInArr5:=ARRAY['test','test2'];


RETURN NEXT is(_as_search_match_array(searchForArr5,searchInArr5),expectedRes5,'search for 0 elements in non-empty arr fails');


expectedRes6:=true;
searchInArr6:=ARRAY['test','test2'];
searchForArr6:=ARRAY['test']::text[];
RETURN NEXT is(_as_search_match_array(searchForArr6,searchInArr6),expectedRes6,'search for 1 matching non-wildcard element in arr succeeds');

expectedRes7:=true;
searchInArr7:=ARRAY['test','tes'];
searchForArr7:=ARRAY['test%']::text[];
RETURN NEXT is(_as_search_match_array(searchForArr7,searchInArr7),expectedRes7,'search for 1 matching wildcard element in arr succeeds');


expectedRes8:=false;
searchInArr8:=ARRAY['btest','btes'];
searchForArr8:=ARRAY['test%']::text[];
RETURN NEXT is(_as_search_match_array(searchForArr8,searchInArr8),expectedRes8,'search for 1 non-matching wildcard element in arr fails');



expectedRes8:=false;
searchInArr8:=ARRAY['btest','btes'];
searchForArr8:=ARRAY['test%','btes']::text[];
RETURN NEXT is(_as_search_match_array(searchForArr8,searchInArr8),expectedRes8,'search for 1 non-matching wildcard and 1 matching element in arr fails');


expectedRes9:=false;
searchInArr9:=ARRAY['btest','btes','ctest'];
searchForArr9:=ARRAY['%test%','btes']::text[];
RETURN NEXT is(_as_search_match_array(searchForArr8,searchInArr8),expectedRes8,'search for 1 matching wildcard and 1 matching element in arr succeeds');



END;
$$;
