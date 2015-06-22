{% extends "basis.jinja.sql" %}
-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.
{% block body %}
CREATE OR REPLACE FUNCTION as_create_or_import_{{oio_type}}(
  {{oio_type}}_registrering {{oio_type|title}}RegistreringType,
  {{oio_type}}_uuid uuid DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  {{oio_type}}_registrering_id bigint;
  {%for attribut , attribut_fields in attributter.iteritems() %}{{oio_type}}_attr_{{attribut}}_obj {{oio_type}}{{attribut|title}}AttrType;
  {% endfor %}
  {% for tilstand, tilstand_values in tilstande.iteritems() %}{{oio_type}}_tils_{{tilstand}}_obj {{oio_type}}{{tilstand|title}}TilsType;
  {% endfor %}
  {{oio_type}}_relationer {{oio_type|title}}RelationType;

BEGIN

IF {{oio_type}}_uuid IS NULL THEN
    LOOP
    {{oio_type}}_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from {{oio_type}} WHERE id={{oio_type}}_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from {{oio_type}} WHERE id={{oio_type}}_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing {{oio_type}} with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_{{oio_type}} (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',{{oio_type}}_uuid;
END IF;

IF  ({{oio_type}}_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and ({{oio_type}}_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_{{oio_type}}.',({{oio_type}}_registrering.registrering).livscykluskode;
END IF;



INSERT INTO 
      {{oio_type}} (ID)
SELECT
      {{oio_type}}_uuid
;


/*********************************/
--Insert new registrering

{{oio_type}}_registrering_id:=nextval('{{oio_type}}_registrering_id_seq');

INSERT INTO {{oio_type}}_registrering (
      id,
        {{oio_type}}_id,
          registrering
        )
SELECT
      {{oio_type}}_registrering_id,
        {{oio_type}}_uuid,
          ROW (
            TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
            ({{oio_type}}_registrering.registrering).livscykluskode,
            ({{oio_type}}_registrering.registrering).brugerref,
            ({{oio_type}}_registrering.registrering).note
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 {%for attribut , attribut_fields in attributter.iteritems() %}
IF coalesce(array_length({{oio_type}}_registrering.attr{{attribut|title}}, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [{{attribut}}] for [{{oio_type}}]. Oprettelse afbrydes.';
END IF;



IF {{oio_type}}_registrering.attr{{attribut|title}} IS NOT NULL THEN
  FOREACH {{oio_type}}_attr_{{attribut}}_obj IN ARRAY {{oio_type}}_registrering.attr{{attribut|title}}
  LOOP

  IF {%- for field in attribut_fields %}
  ( {{oio_type}}_attr_{{attribut}}_obj.{{field}} IS NOT NULL AND  
  {%- if  attributter_type_override is defined and attributter_type_override[attribut] is defined and attributter_type_override[attribut][field] is defined %} 
  {%-if attributter_type_override[attribut][field] == "text[]" %} coalesce(array_length({{oio_type}}_attr_{{attribut}}_obj.{{field}},1),0)>0
  {%- endif %}
  {%- else %} {{oio_type}}_attr_{{attribut}}_obj.{{field}}<>'' 
  {%- endif %}) 
  {% if (not loop.last)%} OR {% endif %}
   {%- endfor %} THEN

    INSERT INTO {{oio_type}}_attr_{{attribut}} (
      {% for field in attribut_fields %}{{field}},
      {% endfor %}virkning,
      {{oio_type}}_registrering_id
    )
    SELECT
     {% for field in attribut_fields %}{{oio_type}}_attr_{{attribut}}_obj.{{field}},
      {% endfor %}{{oio_type}}_attr_{{attribut}}_obj.virkning,
      {{oio_type}}_registrering_id
    ;
  END IF;

  END LOOP;
END IF;
{% endfor %}
/*********************************/
--Insert states (tilstande)

{% for tilstand, tilstand_values in tilstande.iteritems() %}
--Verification
--For now all declared states are mandatory.
IF coalesce(array_length({{oio_type}}_registrering.tils{{tilstand|title}}, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [{{tilstand}}] for {{oio_type}}. Oprettelse afbrydes.';
END IF;

IF {{oio_type}}_registrering.tils{{tilstand|title}} IS NOT NULL THEN
  FOREACH {{oio_type}}_tils_{{tilstand}}_obj IN ARRAY {{oio_type}}_registrering.tils{{tilstand|title}}
  LOOP

  IF {{oio_type}}_tils_{{tilstand}}_obj.{{tilstand}} IS NOT NULL AND {{oio_type}}_tils_{{tilstand}}_obj.{{tilstand}}<>''::{{oio_type|title}}{{tilstand|title}}Tils THEN

    INSERT INTO {{oio_type}}_tils_{{tilstand}} (
      virkning,
      {{tilstand}},
      {{oio_type}}_registrering_id
    )
    SELECT
      {{oio_type}}_tils_{{tilstand}}_obj.virkning,
      {{oio_type}}_tils_{{tilstand}}_obj.{{tilstand}},
      {{oio_type}}_registrering_id;

  END IF;
  END LOOP;
END IF;
{% endfor %}
/*********************************/
--Insert relations

    INSERT INTO {{oio_type}}_relation (
      {{oio_type}}_registrering_id,
      virkning,
      rel_maal,
      rel_type

    )
    SELECT
      {{oio_type}}_registrering_id,
      a.virkning,
      a.relMaal,
      a.relType
    FROM unnest({{oio_type}}_registrering.relationer) a
    WHERE a.relMaal IS NOT NULL
  ;


RETURN {{oio_type}}_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;
{% endblock %}

