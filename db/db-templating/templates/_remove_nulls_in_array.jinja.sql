{% extends "basis.jinja.sql" %}
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.
{% block body %}


{% for tilstand, tilstand_values in tilstande.iteritems() %}

CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr {{oio_type|title}}{{tilstand|title}}TilsType[])
  RETURNS {{oio_type|title}}{{tilstand|title}}TilsType[] AS
  $$
  DECLARE result {{oio_type|title}}{{tilstand|title}}TilsType[];
  DECLARE element {{oio_type|title}}{{tilstand|title}}TilsType;
  BEGIN

 IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (( element.{{tilstand}} IS NULL ) AND element.virkning IS NULL) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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
{% endfor %}


{%-for attribut , attribut_fields in attributter.iteritems() %}

CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr {{oio_type|title}}{{attribut|title}}AttrType[])
  RETURNS {{oio_type|title}}{{attribut|title}}AttrType[] AS
  $$
  DECLARE result {{oio_type|title}}{{attribut|title}}AttrType[]; 
   DECLARE element {{oio_type|title}}{{attribut|title}}AttrType; 
  BEGIN

  IF inputArr IS NOT NULL THEN
    FOREACH element IN ARRAY  inputArr
    LOOP
      IF element IS NULL OR (( element.{{attribut_fields|join(' IS NULL AND element.')}} IS NULL ) AND element.virkning IS NULL) THEN --CAUTION: foreach on {null} will result in element gets initiated with ROW(null,null....) 
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

{% endfor %}


CREATE OR REPLACE FUNCTION _remove_nulls_in_array(inputArr {{oio_type|title}}RelationType[])
RETURNS {{oio_type|title}}RelationType[] AS
$$
 DECLARE result {{oio_type|title}}RelationType[];
 DECLARE element {{oio_type|title}}RelationType;  
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

{% endblock %}

 