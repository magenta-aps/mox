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
  {{oio_type}}_uuid uuid DEFAULT NULL,
  auth_criteria_arr {{oio_type|title}}RegistreringType[] DEFAULT NULL
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
  auth_filtered_uuids uuid[];
  does_exist boolean;
  new_{{oio_type}}_registrering {{oio_type}}_registrering;
  prev_{{oio_type}}_registrering {{oio_type}}_registrering;
BEGIN

IF {{oio_type}}_uuid IS NULL THEN
    LOOP
    {{oio_type}}_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from {{oio_type}} WHERE id={{oio_type}}_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from {{oio_type}} WHERE id={{oio_type}}_uuid) THEN
    does_exist = True;
ELSE

    does_exist = False;
END IF;

IF  ({{oio_type}}_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and ({{oio_type}}_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode  and ({{oio_type}}_registrering.registrering).livscykluskode<>'Rettet'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_{{oio_type}}.',({{oio_type}}_registrering.registrering).livscykluskode USING ERRCODE='MO400';
END IF;


IF NOT does_exist THEN

    INSERT INTO
          {{oio_type}} (ID)
    SELECT
          {{oio_type}}_uuid;
END IF;


/*********************************/
--Insert new registrering

IF NOT does_exist THEN
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
               ):: RegistreringBase ;
ELSE
    -- This is an update, not an import or create
        new_{{oio_type}}_registrering := _as_create_{{oio_type}}_registrering(
             {{oio_type}}_uuid,
             ({{oio_type}}_registrering.registrering).livscykluskode,
             ({{oio_type}}_registrering.registrering).brugerref,
             ({{oio_type}}_registrering.registrering).note);

        {{oio_type}}_registrering_id := new_{{oio_type}}_registrering.id;
END IF;


/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 {%for attribut , attribut_fields in attributter.iteritems() %}
IF coalesce(array_length({{oio_type}}_registrering.attr{{attribut|title}}, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [{{attribut}}] for [{{oio_type}}]. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;



IF {{oio_type}}_registrering.attr{{attribut|title}} IS NOT NULL and coalesce(array_length({{oio_type}}_registrering.attr{{attribut|title}},1),0)>0 THEN
  FOREACH {{oio_type}}_attr_{{attribut}}_obj IN ARRAY {{oio_type}}_registrering.attr{{attribut|title}}
  LOOP

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
 

  END LOOP;
END IF;
{% endfor %}
/*********************************/
--Insert states (tilstande)

{% for tilstand, tilstand_values in tilstande.iteritems() %}
--Verification
--For now all declared states are mandatory.
IF coalesce(array_length({{oio_type}}_registrering.tils{{tilstand|title}}, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [{{tilstand}}] for {{oio_type}}. Oprettelse afbrydes.' USING ERRCODE='MO400';
END IF;

IF {{oio_type}}_registrering.tils{{tilstand|title}} IS NOT NULL AND coalesce(array_length({{oio_type}}_registrering.tils{{tilstand|title}},1),0)>0 THEN
  FOREACH {{oio_type}}_tils_{{tilstand}}_obj IN ARRAY {{oio_type}}_registrering.tils{{tilstand|title}}
  LOOP

    INSERT INTO {{oio_type}}_tils_{{tilstand}} (
      virkning,
      {{tilstand}},
      {{oio_type}}_registrering_id
    )
    SELECT
      {{oio_type}}_tils_{{tilstand}}_obj.virkning,
      {{oio_type}}_tils_{{tilstand}}_obj.{{tilstand}},
      {{oio_type}}_registrering_id;

  END LOOP;
END IF;
{% endfor %}
/*********************************/
--Insert relations

    INSERT INTO {{oio_type}}_relation (
      {{oio_type}}_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      {{oio_type}}_registrering_id,
      a.virkning,
      a.uuid,
      a.urn,
      a.relType,
      a.objektType
    FROM unnest({{oio_type}}_registrering.relationer) a
  ;


/*** Verify that the object meets the stipulated access allowed criteria  ***/
/*** NOTICE: We are doing this check *after* the insertion of data BUT *before* transaction commit, to reuse code / avoid fragmentation  ***/
auth_filtered_uuids:=_as_filter_unauth_{{oio_type}}(array[{{oio_type}}_uuid]::uuid[],auth_criteria_arr); 
IF NOT (coalesce(array_length(auth_filtered_uuids,1),0)=1 AND auth_filtered_uuids @>ARRAY[{{oio_type}}_uuid]) THEN
  RAISE EXCEPTION 'Unable to create/import {{oio_type}} with uuid [%]. Object does not met stipulated criteria:%',{{oio_type}}_uuid,to_json(auth_criteria_arr)  USING ERRCODE = 'MO401'; 
END IF;
/*********************/


  PERFORM actual_state._amqp_publish_notification('{{oio_type|title}}', ({{oio_type}}_registrering.registrering).livscykluskode, {{oio_type}}_uuid);

RETURN {{oio_type}}_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;
{% endblock %}

