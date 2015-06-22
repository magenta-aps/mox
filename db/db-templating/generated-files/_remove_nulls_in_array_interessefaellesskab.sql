-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py interessefaellesskab _remove_nulls_in_array.jinja.sql
*/





CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr InteressefaellesskabGyldighedTilsType[])
  RETURNS InteressefaellesskabGyldighedTilsType[] AS
  $$
  DECLARE result InteressefaellesskabGyldighedTilsType[];
  DECLARE element InteressefaellesskabGyldighedTilsType;
  BEGIN

 IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (( element.gyldighed IS NULL ) AND element.virkning IS NULL) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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


CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr InteressefaellesskabEgenskaberAttrType[])
  RETURNS InteressefaellesskabEgenskaberAttrType[] AS
  $$
  DECLARE result InteressefaellesskabEgenskaberAttrType[]; 
   DECLARE element InteressefaellesskabEgenskaberAttrType; 
  BEGIN

  IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (( element.brugervendtnoegle IS NULL AND element.interessefaellesskabsnavn IS NULL AND element.interessefaellesskabstype IS NULL ) AND element.virkning IS NULL) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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




CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr InteressefaellesskabRelationType[])
RETURNS InteressefaellesskabRelationType[] AS
$$
 DECLARE result InteressefaellesskabRelationType[];
 DECLARE element InteressefaellesskabRelationType;  
  BEGIN

   IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR ( element.relType IS NULL AND element.relMaalUuid IS NULL AND element.relMaalUrn IS NULL AND element.virkning IS NULL  ) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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



