-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py klasse _remove_nulls_in_array.jinja.sql
*/





CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr KlassePubliceretTilsType[])
  RETURNS KlassePubliceretTilsType[] AS
  $$
  DECLARE result KlassePubliceretTilsType[];
  DECLARE element KlassePubliceretTilsType;
  BEGIN

 IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (( element.publiceret IS NULL ) AND element.virkning IS NULL) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
     -- RAISE DEBUG 'Skipping element';
      ELSE 
      result:=array_append(result,element);
      END IF;
    END LOOP;
  ELSE
    return null;  
  END IF;

  RETURN result;

  END;
 
 $$ LANGUAGE plpgsql IMMUTABLE
;


CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr KlasseEgenskaberAttrType[])
  RETURNS KlasseEgenskaberAttrType[] AS
  $$
  DECLARE result KlasseEgenskaberAttrType[]; 
   DECLARE element KlasseEgenskaberAttrType; 
  BEGIN

  IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (( element.brugervendtnoegle IS NULL AND element.beskrivelse IS NULL AND element.eksempel IS NULL AND element.omfang IS NULL AND element.titel IS NULL AND element.retskilde IS NULL AND element.aendringsnotat IS NULL ) AND element.virkning IS NULL AND (element.soegeord IS NULL OR coalesce(array_length(element.soegeord,1),0)=0 )) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
    --  RAISE DEBUG 'Skipping element';
      ELSE
      result:=array_append(result,element);
      END IF;
    END LOOP;
  ELSE
    return null;  
  END IF;

  RETURN result;

  END;
 
 $$ LANGUAGE plpgsql IMMUTABLE
;




CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr KlasseRelationType[])
RETURNS KlasseRelationType[] AS
$$
 DECLARE result KlasseRelationType[];
 DECLARE element KlasseRelationType;  
  BEGIN

   IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR ( element.relType IS NULL AND element.relMaal IS NULL AND element.virkning IS NULL  ) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
      --RAISE DEBUG 'Skipping element';
      ELSE
      result:=array_append(result,element);
      END IF;
    END LOOP;
  ELSE
    return null;  
  END IF;

  RETURN result;
    
  END;
 
 $$ LANGUAGE plpgsql IMMUTABLE
;


CREATE OR REPLACE FUNCTION _remove_nulls_in_array_and_null_empty_array(inputArr KlasseSoegeordType[])
  RETURNS KlasseSoegeordType[] AS
  $$
  DECLARE result KlasseSoegeordType[];
  DECLARE element KlasseSoegeordType;
  BEGIN

 IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (element.soegeordidentifikator IS NULL AND element.beskrivelse IS NULL AND element.soegeordskategori IS NULL ) THEN
     -- RAISE DEBUG 'Skipping element';
      ELSE
      result:=array_append(result,element);
      END IF;
    END LOOP;
  ELSE
    return null;  
  END IF;

  IF array_length(result,1)=0 THEN
    RETURN NULL;
  ELSE
    RETURN result;
  END IF;

  END;
 
 $$ LANGUAGE plpgsql IMMUTABLE
;

