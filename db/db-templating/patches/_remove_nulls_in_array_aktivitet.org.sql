-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py aktivitet _remove_nulls_in_array.jinja.sql
*/





CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr AktivitetStatusTilsType[])
  RETURNS AktivitetStatusTilsType[] AS
  $$
  DECLARE result AktivitetStatusTilsType[];
  DECLARE element AktivitetStatusTilsType;
  BEGIN

 IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (( element.status IS NULL ) AND element.virkning IS NULL) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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


CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr AktivitetPubliceretTilsType[])
  RETURNS AktivitetPubliceretTilsType[] AS
  $$
  DECLARE result AktivitetPubliceretTilsType[];
  DECLARE element AktivitetPubliceretTilsType;
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


CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr AktivitetEgenskaberAttrType[])
  RETURNS AktivitetEgenskaberAttrType[] AS
  $$
  DECLARE result AktivitetEgenskaberAttrType[]; 
   DECLARE element AktivitetEgenskaberAttrType; 
  BEGIN

  IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (( element.brugervendtnoegle IS NULL AND element.aktivitetnavn IS NULL AND element.beskrivelse IS NULL AND element.starttidspunkt IS NULL AND element.sluttidspunkt IS NULL AND element.tidsforbrug IS NULL AND element.formaal IS NULL ) AND element.virkning IS NULL) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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




CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr AktivitetRelationType[])
RETURNS AktivitetRelationType[] AS
$$
 DECLARE result AktivitetRelationType[];
 DECLARE element AktivitetRelationType;  
  BEGIN

   IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR ( element.relType IS NULL AND element.uuid IS NULL AND element.urn IS NULL AND element.objektType IS NULL AND element.indeks IS NULL AND (element.aktoerAttr IS NULL OR ((element.aktoerAttr).obligatorisk IS NULL AND (element.aktoerAttr).accepteret IS NULL AND (element.aktoerAttr).repraesentation_uuid IS NULL AND (element.aktoerAttr).repraesentation_urn IS NULL    )) AND element.virkning IS NULL  ) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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



