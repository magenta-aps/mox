-- SPDX-FileCopyrightText: 2015-2020 Magenta ApS
-- SPDX-License-Identifier: MPL-2.0

--SELECT * FROM runtests('test'::name);
CREATE OR REPLACE FUNCTION test.test_as_search_ilike_array()
RETURNS SETOF TEXT LANGUAGE plpgsql AS 
$$
DECLARE 
searchFor1 text;
searchInArr1 text[] ;
expectedRes1 boolean;
searchFor2 text;
searchInArr2 text[];
expectedRes2 boolean;
searchFor3 text;
searchInArr3 text[] ;
expectedRes3 boolean;
searchFor4 text;
searchInArr4 text[] ;
expectedRes4 boolean;
searchFor5 text;
searchInArr5 text[] ;
expectedRes5 boolean;
searchFor6 text;
searchInArr6 text[] ;
expectedRes6 boolean;
searchFor7 text;
searchInArr7 text[] ;
expectedRes7 boolean;
searchFor8 text;
searchInArr8 text[] ;
expectedRes8 boolean;
searchFor9 text;
searchInArr9 text[] ;
expectedRes9 boolean;
BEGIN



expectedRes1:=false;

RETURN NEXT is(_as_search_ilike_array(searchFor1,searchInArr1),expectedRes1,'search for null in null does not matches');

expectedRes2:=false;

searchFor2:='test';

RETURN NEXT is(_as_search_ilike_array(searchFor2,searchInArr2),expectedRes2,'search for one element in null fails');


expectedRes3:=false;

searchInArr3:=ARRAY['test','test2'];

RETURN NEXT is(_as_search_ilike_array(searchFor3,searchInArr3),expectedRes3,'search for null array fails');


expectedRes4:=true;

searchInArr4:=ARRAY['skole','test'];
searchFor4:='skole';
RETURN NEXT is(_as_search_ilike_array(searchFor4,searchInArr4),expectedRes4,'search for 1 element should match');


expectedRes5:=false;

searchInArr5:=ARRAY['skole','test'];
searchFor5:='skole2';


RETURN NEXT is(_as_search_ilike_array(searchFor5,searchInArr5),expectedRes5,'search for 1 elements in non-empty arr fails');


expectedRes6:=true;

searchInArr6:=ARRAY['skole','test'];
searchFor6:='tes%';


RETURN NEXT is(_as_search_ilike_array(searchFor6,searchInArr6),expectedRes6,'search for 1 elements in non-empty with wildcard');


expectedRes7:=false;

searchInArr7:=ARRAY['skole','test'];
searchFor7:='tes';


RETURN NEXT is(_as_search_ilike_array(searchFor7,searchInArr7),expectedRes7,'search for 1 elements in non-empty with wildcard #2');


expectedRes8:=false;

searchInArr8:=ARRAY[]::text[];
searchFor8:='';


RETURN NEXT is(_as_search_ilike_array(searchFor8,searchInArr8),expectedRes8,'search for empty string empty array');



expectedRes9:=false;

searchInArr9:=ARRAY[]::text[];
searchFor9:=null;


RETURN NEXT is(_as_search_ilike_array(searchFor9,searchInArr9),expectedRes9,'search for null in empty empty array');



END;
$$;
