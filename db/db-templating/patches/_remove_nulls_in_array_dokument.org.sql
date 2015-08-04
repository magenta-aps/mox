-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py dokument _remove_nulls_in_array.jinja.sql
*/





CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr DokumentFremdriftTilsType[])
  RETURNS DokumentFremdriftTilsType[] AS
  $$
  DECLARE result DokumentFremdriftTilsType[];
  DECLARE element DokumentFremdriftTilsType;
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


CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr DokumentEgenskaberAttrType[])
  RETURNS DokumentEgenskaberAttrType[] AS
  $$
  DECLARE result DokumentEgenskaberAttrType[]; 
   DECLARE element DokumentEgenskaberAttrType; 
  BEGIN

  IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (( element.brugervendtnoegle IS NULL AND element.beskrivelse IS NULL AND element.brevdato IS NULL AND element.kassationskode IS NULL AND element.major IS NULL AND element.minor IS NULL AND element.offentlighedundtaget IS NULL AND element.titel IS NULL AND element.dokumenttype IS NULL ) AND element.virkning IS NULL) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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




CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr DokumentRelationType[])
RETURNS DokumentRelationType[] AS
$$
 DECLARE result DokumentRelationType[];
 DECLARE element DokumentRelationType;  
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


/********************************************/
/* Handle document variants and parts */


CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr DokumentVariantEgenskaberType[])
  RETURNS DokumentVariantEgenskaberType[] AS
  $$
  DECLARE result DokumentVariantEgenskaberType[]; 
   DECLARE element DokumentVariantEgenskaberType; 
  BEGIN

  IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (( element.arkivering IS NULL AND element.delvisscannet IS NULL AND element.offentliggoerelse IS NULL AND element.produktion IS NULL ) AND element.virkning IS NULL) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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


CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr DokumentDelEgenskaberType[])
  RETURNS DokumentDelEgenskaberType[] AS
  $$
  DECLARE result DokumentDelEgenskaberType[]; 
   DECLARE element DokumentDelEgenskaberType; 
  BEGIN

  IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (( element.indeks IS NULL AND element.indhold IS NULL AND element.lokation IS NULL AND element.mimetype IS NULL ) AND element.virkning IS NULL) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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



CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr DokumentdelRelationType[])
RETURNS DokumentdelRelationType[] AS
$$
 DECLARE result DokumentdelRelationType[];
 DECLARE element DokumentdelRelationType;  
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






