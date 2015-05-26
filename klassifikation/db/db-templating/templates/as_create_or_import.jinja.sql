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
  {{oio_type}}_uuid uuid DEFAULT public.uuid_generate_v4() --This might genenerate a non unique value. Use uuid_generate_v5(). Consider using uuid_generate_v5() and namespace(s). Consider generating using sequences which generates input to hash, with a namespace part and a id part.
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

IF EXISTS (SELECT id from {{oio_type}} WHERE id={{oio_type}}_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing {{oio_type}} with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_{{oio_type}} (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might occur, albeit very very rarely.',{{oio_type}}_uuid;
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
IF array_length({{oio_type}}_registrering.attr{{attribut|title}}, 1)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [{{attribut}}] for [{{oio_type}}]. Oprettelse afbrydes.';
END IF;



IF {{oio_type}}_registrering.attr{{attribut|title}} IS NOT NULL THEN
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
IF array_length({{oio_type}}_registrering.tils{{tilstand|title}}, 1)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [{{tilstand}}] for {{oio_type}}. Oprettelse afbrydes.';
END IF;

IF {{oio_type}}_registrering.tils{{tilstand|title}} IS NOT NULL THEN
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
      rel_maal,
      rel_type

    )
    SELECT
      {{oio_type}}_registrering_id,
      a.virkning,
      a.relMaal,
      a.relType
    FROM unnest({{oio_type}}_registrering.relationer) a
  ;


RETURN {{oio_type}}_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;
{% endblock %}

