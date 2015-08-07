-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: apply-template.py dokument as_create_or_import.jinja.sql
*/

CREATE OR REPLACE FUNCTION as_create_or_import_dokument(
  dokument_registrering DokumentRegistreringType,
  dokument_uuid uuid DEFAULT NULL
	)
  RETURNS uuid AS 
$$
DECLARE
  dokument_registrering_id bigint;
  dokument_attr_egenskaber_obj dokumentEgenskaberAttrType;
  
  dokument_tils_fremdrift_obj dokumentFremdriftTilsType;
  
  dokument_relationer DokumentRelationType;
  dokument_variant_obj DokumentVariantType;
  dokument_variant_egenskab_obj DokumentVariantEgenskaberType;
  dokument_del_obj DokumentDelType;
  dokument_del_egenskaber_obj DokumentDelEgenskaberType;
  dokument_del_relation_obj DokumentDelRelationType;
  dokument_variant_new_id bigint;
  dokument_del_new_id bigint;
BEGIN

IF dokument_uuid IS NULL THEN
    LOOP
    dokument_uuid:=uuid_generate_v4();
    EXIT WHEN NOT EXISTS (SELECT id from dokument WHERE id=dokument_uuid); 
    END LOOP;
END IF;


IF EXISTS (SELECT id from dokument WHERE id=dokument_uuid) THEN
  RAISE EXCEPTION 'Error creating or importing dokument with uuid [%]. If you did not supply the uuid when invoking as_create_or_import_dokument (i.e. create operation) please try to repeat the invocation/operation, that id collison with randomly generated uuids might in theory occur, albeit very very very rarely.',dokument_uuid;
END IF;

IF  (dokument_registrering.registrering).livscykluskode<>'Opstaaet'::Livscykluskode and (dokument_registrering.registrering).livscykluskode<>'Importeret'::Livscykluskode THEN
  RAISE EXCEPTION 'Invalid livscykluskode[%] invoking as_create_or_import_dokument.',(dokument_registrering.registrering).livscykluskode;
END IF;



INSERT INTO 
      dokument (ID)
SELECT
      dokument_uuid
;


/*********************************/
--Insert new registrering

dokument_registrering_id:=nextval('dokument_registrering_id_seq');

INSERT INTO dokument_registrering (
      id,
        dokument_id,
          registrering
        )
SELECT
      dokument_registrering_id,
        dokument_uuid,
          ROW (
            TSTZRANGE(clock_timestamp(),'infinity'::TIMESTAMPTZ,'[)' ),
            (dokument_registrering.registrering).livscykluskode,
            (dokument_registrering.registrering).brugerref,
            (dokument_registrering.registrering).note
              ):: RegistreringBase
;

/*********************************/
--Insert attributes


/************/
--Verification
--For now all declared attributes are mandatory (the fields are all optional,though)

 
IF coalesce(array_length(dokument_registrering.attrEgenskaber, 1),0)<1 THEN
  RAISE EXCEPTION 'Savner påkraevet attribut [egenskaber] for [dokument]. Oprettelse afbrydes.';
END IF;



IF dokument_registrering.attrEgenskaber IS NOT NULL THEN
  FOREACH dokument_attr_egenskaber_obj IN ARRAY dokument_registrering.attrEgenskaber
  LOOP

  IF
  ( dokument_attr_egenskaber_obj.brugervendtnoegle IS NOT NULL AND dokument_attr_egenskaber_obj.brugervendtnoegle<>'') 
   OR 
  ( dokument_attr_egenskaber_obj.beskrivelse IS NOT NULL AND dokument_attr_egenskaber_obj.beskrivelse<>'') 
   OR 
  ( dokument_attr_egenskaber_obj.brevdato IS NOT NULL) 
   OR 
  ( dokument_attr_egenskaber_obj.kassationskode IS NOT NULL AND dokument_attr_egenskaber_obj.kassationskode<>'') 
   OR 
  ( dokument_attr_egenskaber_obj.major IS NOT NULL) 
   OR 
  ( dokument_attr_egenskaber_obj.minor IS NOT NULL) 
   OR 
  ( dokument_attr_egenskaber_obj.offentlighedundtaget IS NOT NULL OR ((dokument_attr_egenskaber_obj.offentlighedundtaget).AlternativTitel IS NOT NULL AND (dokument_attr_egenskaber_obj.offentlighedundtaget).AlternativTitel<>'') OR ((dokument_attr_egenskaber_obj.offentlighedundtaget).Hjemmel IS NOT NULL AND (dokument_attr_egenskaber_obj.offentlighedundtaget).Hjemmel<>'')) 
   OR 
  ( dokument_attr_egenskaber_obj.titel IS NOT NULL AND dokument_attr_egenskaber_obj.titel<>'') 
   OR 
  ( dokument_attr_egenskaber_obj.dokumenttype IS NOT NULL AND dokument_attr_egenskaber_obj.dokumenttype<>'') 
   THEN

    INSERT INTO dokument_attr_egenskaber (
      brugervendtnoegle,
      beskrivelse,
      brevdato,
      kassationskode,
      major,
      minor,
      offentlighedundtaget,
      titel,
      dokumenttype,
      virkning,
      dokument_registrering_id
    )
    SELECT
     dokument_attr_egenskaber_obj.brugervendtnoegle,
      dokument_attr_egenskaber_obj.beskrivelse,
      dokument_attr_egenskaber_obj.brevdato,
      dokument_attr_egenskaber_obj.kassationskode,
      dokument_attr_egenskaber_obj.major,
      dokument_attr_egenskaber_obj.minor,
      dokument_attr_egenskaber_obj.offentlighedundtaget,
      dokument_attr_egenskaber_obj.titel,
      dokument_attr_egenskaber_obj.dokumenttype,
      dokument_attr_egenskaber_obj.virkning,
      dokument_registrering_id
    ;
  END IF;

  END LOOP;
END IF;

/*********************************/
--Insert states (tilstande)


--Verification
--For now all declared states are mandatory.
IF coalesce(array_length(dokument_registrering.tilsFremdrift, 1),0)<1  THEN
  RAISE EXCEPTION 'Savner påkraevet tilstand [fremdrift] for dokument. Oprettelse afbrydes.';
END IF;

IF dokument_registrering.tilsFremdrift IS NOT NULL THEN
  FOREACH dokument_tils_fremdrift_obj IN ARRAY dokument_registrering.tilsFremdrift
  LOOP

  IF dokument_tils_fremdrift_obj.fremdrift IS NOT NULL AND dokument_tils_fremdrift_obj.fremdrift<>''::DokumentFremdriftTils THEN

    INSERT INTO dokument_tils_fremdrift (
      virkning,
      fremdrift,
      dokument_registrering_id
    )
    SELECT
      dokument_tils_fremdrift_obj.virkning,
      dokument_tils_fremdrift_obj.fremdrift,
      dokument_registrering_id;

  END IF;
  END LOOP;
END IF;

/*********************************/
--Insert relations

    INSERT INTO dokument_relation (
      dokument_registrering_id,
      virkning,
      rel_maal_uuid,
      rel_maal_urn,
      rel_type,
      objekt_type
    )
    SELECT
      dokument_registrering_id,
      a.virkning,
      a.relMaalUuid,
      a.relMaalUrn,
      a.relType,
      a.objektType
    FROM unnest(dokument_registrering.relationer) a
    WHERE (a.relMaalUuid IS NOT NULL OR (a.relMaalUrn IS NOT NULL AND a.relMaalUrn<>'') )
  ;


/*********************************/
--Insert document variants (and parts)

IF dokument_registrering.varianter IS NOT NULL AND coalesce(array_length(dokument_registrering.varianter,1),0)>0 THEN
  

FOREACH dokument_variant_obj IN ARRAY dokument_registrering.varianter
LOOP

dokument_variant_new_id:=nextval('dokument_variant_id_seq'::regclass);

  INSERT INTO dokument_variant (
      id,
        varianttekst,
          dokument_registrering_id
  )
  VALUES
  (
      dokument_variant_new_id,
        dokument_variant_obj.varianttekst,
          dokument_registrering_id
  ); 


  IF dokument_variant_obj.egenskaber IS NOT NULL AND coalesce(array_length(dokument_variant_obj.egenskaber,1),0)>0 THEN

    FOREACH dokument_variant_egenskab_obj IN ARRAY dokument_variant_obj.egenskaber
    LOOP

     INSERT INTO dokument_variant_egenskaber (
      variant_id,
        arkivering, 
          delvisscannet, 
            offentliggoerelse, 
              produktion,
                virkning
      )
      SELECT
      dokument_variant_new_id,  
        dokument_variant_egenskab_obj.arkivering,
          dokument_variant_egenskab_obj.delvisscannet,
            dokument_variant_egenskab_obj.offentliggoerelse,
              dokument_variant_egenskab_obj.produktion,
                dokument_variant_egenskab_obj.virkning
      ;

    END LOOP; --variant_egenskaber
  END IF; --variant_egenskaber


  IF dokument_variant_obj.dele IS NOT NULL AND coalesce(array_length(dokument_variant_obj.dele,1),0)>0 THEN

    FOREACH dokument_del_obj IN ARRAY dokument_variant_obj.dele
    LOOP

    dokument_del_new_id:=nextval('dokument_del_id_seq'::regclass);

  INSERT INTO dokument_del (
    id,
      deltekst,
        variant_id
    )
    VALUES
    (
    dokument_del_new_id,
        dokument_del_obj.deltekst,
          dokument_variant_new_id
    )
    ;

    IF dokument_del_obj.egenskaber IS NOT NULL AND coalesce(array_length(dokument_del_obj.egenskaber,1),0)>0 THEN

    FOREACH dokument_del_egenskaber_obj IN ARRAY dokument_del_obj.egenskaber
    LOOP

    INSERT INTO
    dokument_del_egenskaber (
      del_id,
        indeks, 
          indhold, 
            lokation, 
              mimetype, 
                virkning
    )
    VALUES
    (
      dokument_del_new_id, 
        dokument_del_egenskaber_obj.indeks,
          dokument_del_egenskaber_obj.indhold,
            dokument_del_egenskaber_obj.lokation,
              dokument_del_egenskaber_obj.mimetype,
                dokument_del_egenskaber_obj.virkning
    )
    ;                

    END LOOP;--del_egenskaber
    END IF; --del_egenskaber

    IF dokument_del_obj.relationer IS NOT NULL AND coalesce(array_length(dokument_del_obj.relationer,1),0)>0 THEN

    FOREACH dokument_del_relation_obj IN ARRAY dokument_del_obj.relationer
    LOOP

      INSERT INTO dokument_del_relation (
        del_id,
          virkning,
            rel_maal_uuid, 
              rel_maal_urn,
                rel_type,
                  objekt_type
      )
      VALUES
      (
        dokument_del_new_id,
          dokument_del_relation_obj.virkning,
            dokument_del_relation_obj.relMaalUuid,
              dokument_del_relation_obj.relMaalUrn,
                dokument_del_relation_obj.relType,
                  dokument_del_relation_obj.objektType
      )
      ;

    END LOOP;--del_relationer

    END IF; --dokument_del_obj.relationer

    END LOOP; --variant_dele
  END IF; 

 END LOOP; --varianter


END IF; --varianter

  PERFORM actual_state._amqp_publish_notification('Dokument', (dokument_registrering.registrering).livscykluskode, dokument_uuid);

RETURN dokument_uuid;

END;
$$ LANGUAGE plpgsql VOLATILE;


