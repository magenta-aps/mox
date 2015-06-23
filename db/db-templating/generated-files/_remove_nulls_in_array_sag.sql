-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py sag _remove_nulls_in_array.jinja.sql
*/





CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr SagFremdriftTilsType[])
  RETURNS SagFremdriftTilsType[] AS
  $$
  DECLARE result SagFremdriftTilsType[];
  DECLARE element SagFremdriftTilsType;
  BEGIN

 IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (( element.fremdrift IS NULL ) AND element.virkning IS NULL) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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


CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr SagEgenskaberAttrType[])
  RETURNS SagEgenskaberAttrType[] AS
  $$
  DECLARE result SagEgenskaberAttrType[]; 
   DECLARE element SagEgenskaberAttrType; 
  BEGIN

  IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (( element.brugervendtnoegle IS NULL AND element.afleveret IS NULL AND element.beskrivelse IS NULL AND element.hjemmel IS NULL AND element.kassationskode IS NULL AND element.offentlighedundtaget IS NULL AND element.principiel IS NULL AND element.sagsnummer IS NULL AND element.titel IS NULL ) AND element.virkning IS NULL) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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




CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr SagRelationType[])
RETURNS SagRelationType[] AS
$$
 DECLARE result SagRelationType[];
 DECLARE element SagRelationType;  
  BEGIN

   IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR ( element.relType IS NULL AND element.relMaalUuid IS NULL AND element.relMaalUrn IS NULL AND element.objektType IS NULL AND element.virkning IS NULL  ) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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



