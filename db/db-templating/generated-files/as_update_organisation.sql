-- Copyright (C) 2015 Magenta ApS, http://magenta.dk.
-- Contact: info@magenta.dk.
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

/*
NOTICE: This file is auto-generated using the script: oio_rest/apply-templates.py
*/


-- Also notice, that the given arrays of OrganisationAttr...Type
-- must be consistent regarding virkning (although the allowance of
-- null-values might make it possible to construct
-- 'logically consistent'-arrays of objects with overlapping virknings)
CREATE OR REPLACE FUNCTION as_update_organisation(
    organisation_uuid uuid,
    brugerref         uuid,
    note              text,
    livscykluskode    Livscykluskode,

    
    attrEgenskaber OrganisationEgenskaberAttrType[],
    

    
    tilsGyldighed OrganisationGyldighedTilsType[],
    

    relationer OrganisationRelationType[],

    

    lostUpdatePreventionTZ TIMESTAMPTZ = null,
    auth_criteria_arr      OrganisationRegistreringType[] = null
) RETURNS bigint AS $$
DECLARE
    read_new_organisation          OrganisationType;
    read_prev_organisation         OrganisationType;
    read_new_organisation_reg      OrganisationRegistreringType;
    read_prev_organisation_reg     OrganisationRegistreringType;
    new_organisation_registrering  organisation_registrering;
    prev_organisation_registrering organisation_registrering;
    organisation_relation_navn     OrganisationRelationKode;

    
    attrEgenskaberObj OrganisationEgenskaberAttrType;
    

    

    auth_filtered_uuids uuid[];

    
BEGIN
    -- Create a new registrering
    IF NOT EXISTS (select a.id from organisation a join organisation_registrering b ON b.organisation_id=a.id WHERE a.id=organisation_uuid) THEN
        RAISE EXCEPTION 'Unable to update organisation with uuid [%], being unable to find any previous registrations.',organisation_uuid USING ERRCODE = 'MO400';
    END IF;

    -- We synchronize concurrent invocations of as_updates of this particular
    -- object on a exclusive row lock. This lock will be held by the current
    -- transaction until it terminates.
    PERFORM a.id FROM organisation a WHERE a.id=organisation_uuid FOR UPDATE;

    -- Verify that the object meets the stipulated access allowed criteria
    auth_filtered_uuids := _as_filter_unauth_organisation(array[organisation_uuid]::uuid[], auth_criteria_arr);
    IF NOT (coalesce(array_length(auth_filtered_uuids, 1), 0) = 1 AND auth_filtered_uuids @>ARRAY[organisation_uuid]) THEN
      RAISE EXCEPTION 'Unable to update organisation with uuid [%]. Object does not met stipulated criteria:%', organisation_uuid, to_json(auth_criteria_arr) USING ERRCODE = 'MO401';
    END IF;

    new_organisation_registrering := _as_create_organisation_registrering(organisation_uuid, livscykluskode, brugerref, note);
    prev_organisation_registrering := _as_get_prev_organisation_registrering(new_organisation_registrering);

    IF lostUpdatePreventionTZ IS NOT NULL THEN
      IF NOT (LOWER((prev_organisation_registrering.registrering).timeperiod) = lostUpdatePreventionTZ) THEN
        RAISE EXCEPTION 'Unable to update organisation with uuid [%], as the organisation seems to have been updated since latest read by client (the given lostUpdatePreventionTZ [%] does not match the timesamp of latest registration [%]).', organisation_uuid, lostUpdatePreventionTZ, LOWER((prev_organisation_registrering.registrering).timeperiod) USING ERRCODE = 'MO409';
      END IF;
    END IF;

    -- Handle relationer (relations)
    IF relationer IS NOT NULL AND coalesce(array_length(relationer, 1), 0) = 0 THEN
        -- raise notice 'Skipping relations, as it is explicit set to empty array. Update note [%]', note;
    ELSE

    -- 1) Insert relations given as part of this update
    -- 2) for aktivitet: Insert relations of previous registration, with index
    --      values not included in this update. Please notice that for the
    --      logic to work, it is very important that the index sequences
    --      start with the max value for index of the same type in the
    --      previous registration
    -- 2) for everything else: Insert relations of previous registration,
    --      taking overlapping virknings into consideration
    --      (using function subtract_tstzrange)

    --Ad 1)
    

    INSERT INTO organisation_relation (organisation_registrering_id, virkning, rel_maal_uuid, rel_maal_urn, rel_type, objekt_type )
    SELECT
        new_organisation_registrering.id,
        a.virkning,
        a.uuid,
        a.urn,
        a.relType,
        a.objektType 
        FROM
            unnest(relationer) AS a ;

    


    -- Ad 2)
    -- 0..1 relations

    
    
    FOREACH organisation_relation_navn IN ARRAY ARRAY['branche'::OrganisationRelationKode ,  'myndighed'::OrganisationRelationKode ,  'myndighedstype'::OrganisationRelationKode ,  'overordnet'::OrganisationRelationKode ,  'produktionsenhed'::OrganisationRelationKode ,  'skatteenhed'::OrganisationRelationKode ,  'tilhoerer'::OrganisationRelationKode ,  'virksomhed'::OrganisationRelationKode ,  'virksomhedstype'::OrganisationRelationKode  ]::OrganisationRelationKode[]  LOOP
        INSERT INTO organisation_relation (organisation_registrering_id, virkning, rel_maal_uuid, rel_maal_urn, rel_type, objekt_type )
        SELECT
            new_organisation_registrering.id,
            ROW (c.tz_range_leftover,
                (a.virkning).AktoerRef,
                (a.virkning).AktoerTypeKode,
                (a.virkning).NoteTekst)::virkning,
            a.rel_maal_uuid,
            a.rel_maal_urn,
            a.rel_type,
            a.objekt_type 
            FROM (
                -- Build an array of the timeperiod of the virkning of the
                -- relations of the new registrering to pass to
                -- _subtract_tstzrange_arr on the relations of the previous
                -- registrering.
                SELECT coalesce(array_agg((b.virkning).TimePeriod), ARRAY[]::TSTZRANGE[]) tzranges_of_new_reg
                  FROM organisation_relation b
                 WHERE b.organisation_registrering_id = new_organisation_registrering.id AND b.rel_type = organisation_relation_navn) d
            JOIN organisation_relation a ON TRUE
            JOIN unnest(_subtract_tstzrange_arr ((a.virkning).TimePeriod, tzranges_of_new_reg)) AS c (tz_range_leftover) ON TRUE
        WHERE
            a.organisation_registrering_id = prev_organisation_registrering.id AND a.rel_type = organisation_relation_navn;
    END LOOP;

    -- 0..n relations
    -- We only have to check if there are any of the relations with the
    -- given name present in the new registration, otherwise copy the ones
    -- from the previous registration.

    
    FOREACH organisation_relation_navn IN ARRAY ARRAY['adresser'::OrganisationRelationKode, 'ansatte'::OrganisationRelationKode, 'opgaver'::OrganisationRelationKode, 'tilknyttedebrugere'::OrganisationRelationKode, 'tilknyttedeenheder'::OrganisationRelationKode, 'tilknyttedefunktioner'::OrganisationRelationKode, 'tilknyttedeinteressefaellesskaber'::OrganisationRelationKode, 'tilknyttedeorganisationer'::OrganisationRelationKode, 'tilknyttedepersoner'::OrganisationRelationKode, 'tilknyttedeitsystemer'::OrganisationRelationKode]::OrganisationRelationKode[] LOOP
        IF NOT EXISTS (
                    SELECT 1
                      FROM organisation_relation
                     WHERE organisation_registrering_id = new_organisation_registrering.id AND rel_type = organisation_relation_navn) THEN
                    
                    INSERT INTO organisation_relation (organisation_registrering_id, virkning, rel_maal_uuid, rel_maal_urn, rel_type, objekt_type )
                    SELECT
                        new_organisation_registrering.id,  virkning, rel_maal_uuid, rel_maal_urn, rel_type, objekt_type
        FROM organisation_relation
        WHERE
            organisation_registrering_id = prev_organisation_registrering.id AND rel_type = organisation_relation_navn ;

    
        END IF;
    END LOOP;
    
    END IF;


    -- Handle tilstande (states)
    
    IF tilsGyldighed IS NOT NULL AND coalesce(array_length(tilsGyldighed, 1), 0) = 0 THEN
        -- raise debug 'Skipping [Gyldighed] as it is explicit set to empty array';
    ELSE
        -- 1) Insert tilstande/states given as part of this update
        -- 2) Insert tilstande/states of previous registration, taking
        --      overlapping virknings into consideration (using function
        --      subtract_tstzrange)

        -- organisation_tils_gyldighed

        -- Ad 1)
        INSERT INTO organisation_tils_gyldighed(virkning, gyldighed, organisation_registrering_id)
             SELECT a.virkning, a.gyldighed, new_organisation_registrering.id
               FROM unnest(tilsGyldighed) AS a;

        -- Ad 2
        INSERT INTO organisation_tils_gyldighed(virkning, gyldighed, organisation_registrering_id)
        SELECT
            ROW (c.tz_range_leftover,
                (a.virkning).AktoerRef,
                (a.virkning).AktoerTypeKode,
                (a.virkning).NoteTekst)::virkning,
            a.gyldighed,
            new_organisation_registrering.id
        FROM (
            -- Build an array of the timeperiod of the virkning of the
            -- organisation_tils_gyldighed of the new registrering to
            -- pass to _subtract_tstzrange_arr on the
            -- organisation_tils_gyldighed of the previous registrering
            SELECT coalesce(array_agg((b.virkning).TimePeriod), ARRAY[]::TSTZRANGE[]) tzranges_of_new_reg
              FROM organisation_tils_gyldighed b
             WHERE b.organisation_registrering_id = new_organisation_registrering.id) d
              JOIN organisation_tils_gyldighed a ON TRUE
              JOIN unnest(_subtract_tstzrange_arr ((a.virkning).TimePeriod, tzranges_of_new_reg)) AS c (tz_range_leftover) ON TRUE
        WHERE a.organisation_registrering_id = prev_organisation_registrering.id;
    END IF;
    


    -- Handle attributter (attributes)
    
    -- organisation_attr_egenskaber

    -- Generate and insert any merged objects, if any fields are null
    -- in attrOrganisationObj
    IF attrEgenskaber IS NOT NULL THEN
        --Input validation:
        --Verify that there is no overlap in virkning in the array given
        IF EXISTS (
                SELECT a.* FROM
                    unnest(attrEgenskaber) a
                    JOIN unnest(attrEgenskaber) b ON (a.virkning).TimePeriod && (b.virkning).TimePeriod
                GROUP BY
                    a.brugervendtnoegle,a.organisationsnavn,
                    a.virkning
                    
                    HAVING COUNT(*) > 1) THEN
                    RAISE EXCEPTION 'Unable to update organisation with uuid [%], as the organisation have overlapping virknings in the given egenskaber array :%', organisation_uuid, to_json(attrEgenskaber) USING ERRCODE = 'MO400';
    END IF;

    FOREACH attrEgenskaberObj IN ARRAY attrEgenskaber LOOP
        -- To avoid needless fragmentation we'll check for presence of
        -- null values in the fields - and if none are present, we'll skip
        -- the merging operations
        IF  (attrEgenskaberObj).brugervendtnoegle IS NULL  OR  (attrEgenskaberObj).organisationsnavn IS NULL  THEN
            
            INSERT INTO organisation_attr_egenskaber ( brugervendtnoegle,organisationsnavn, virkning, organisation_registrering_id)
                SELECT
                    
                        
                        
                            coalesce(attrEgenskaberObj.brugervendtnoegle, a.brugervendtnoegle),
                    
                        
                        
                            coalesce(attrEgenskaberObj.organisationsnavn, a.organisationsnavn),
                    
                    ROW ((a.virkning).TimePeriod * (attrEgenskaberObj.virkning).TimePeriod,
                            (attrEgenskaberObj.virkning).AktoerRef,
                            (attrEgenskaberObj.virkning).AktoerTypeKode,
                            (attrEgenskaberObj.virkning).NoteTekst)::Virkning,
                            new_organisation_registrering.id
                        FROM organisation_attr_egenskaber a
                    WHERE
                        a.organisation_registrering_id = prev_organisation_registrering.id
                        AND (a.virkning).TimePeriod && (attrEgenskaberObj.virkning).TimePeriod
                        ;

        -- For any periods within the virkning of the attrEgenskaberObj,
        -- that is NOT covered by any "merged" rows inserted above, generate
        -- and insert rows.
        
            INSERT INTO organisation_attr_egenskaber ( brugervendtnoegle,organisationsnavn, virkning, organisation_registrering_id)
                SELECT
                    
                     attrEgenskaberObj.brugervendtnoegle,
                    
                     attrEgenskaberObj.organisationsnavn,
                    
                    ROW (b.tz_range_leftover,
                        (attrEgenskaberObj.virkning).AktoerRef,
                        (attrEgenskaberObj.virkning).AktoerTypeKode,
                        (attrEgenskaberObj.virkning).NoteTekst)::Virkning,
                        new_organisation_registrering.id
                    FROM (
                        -- Build an array of the timeperiod of the virkning
                        -- of the organisation_attr_egenskaber of the new
                        -- registrering to pass to _subtract_tstzrange_arr.
                        SELECT
                            coalesce(array_agg((b.virkning).TimePeriod), ARRAY[]::TSTZRANGE[]) tzranges_of_new_reg
                        FROM organisation_attr_egenskaber b
                    WHERE b.organisation_registrering_id = new_organisation_registrering.id) AS a
                    JOIN unnest(_subtract_tstzrange_arr ((attrEgenskaberObj.virkning).TimePeriod, a.tzranges_of_new_reg)) AS b (tz_range_leftover) ON TRUE ;

        ELSE
            -- Insert attrEgenskaberObj raw (if there were no null-valued fields)
            

            INSERT INTO organisation_attr_egenskaber ( brugervendtnoegle,organisationsnavn, virkning, organisation_registrering_id)
                VALUES (  attrEgenskaberObj.brugervendtnoegle,  attrEgenskaberObj.organisationsnavn, attrEgenskaberObj.virkning, new_organisation_registrering.id );
        END IF;

        END LOOP;

        END IF;

        IF attrEgenskaber IS NOT NULL AND coalesce(array_length(attrEgenskaber, 1), 0) = 0 THEN
            -- raise debug 'Skipping handling of egenskaber of previous registration as an empty array was explicit given.';
        ELSE



-- Handle egenskaber of previous registration, taking overlapping
-- virknings into consideration (using function subtract_tstzrange)

    INSERT INTO organisation_attr_egenskaber ( brugervendtnoegle,organisationsnavn, virkning, organisation_registrering_id)
    SELECT
        
        
            a.brugervendtnoegle,
        
            a.organisationsnavn,
        
        ROW (c.tz_range_leftover,
            (a.virkning).AktoerRef,
            (a.virkning).AktoerTypeKode,
            (a.virkning).NoteTekst)::virkning,
            new_organisation_registrering.id
        FROM (
            -- Build an array of the timeperiod of the virkning of the
            -- organisation_attr_egenskaber of the new registrering to
            -- pass to _subtract_tstzrange_arr on the
            -- organisation_attr_egenskaber of the previous registrering.
            SELECT
                coalesce(array_agg((b.virkning).TimePeriod), ARRAY[]::TSTZRANGE[]) tzranges_of_new_reg
            FROM
                organisation_attr_egenskaber b
            WHERE
                b.organisation_registrering_id = new_organisation_registrering.id) d
            JOIN organisation_attr_egenskaber a ON TRUE
            JOIN unnest(_subtract_tstzrange_arr ((a.virkning).TimePeriod, tzranges_of_new_reg)) AS c (tz_range_leftover) ON TRUE
        WHERE
            a.organisation_registrering_id = prev_organisation_registrering.id ;

END IF;






    /******************************************************************/
    -- If the new registrering is identical to the previous one, we need
    -- to throw an exception to abort the transaction.

    read_new_organisation := as_read_organisation(organisation_uuid, (new_organisation_registrering.registrering).timeperiod, null);
    read_prev_organisation := as_read_organisation(organisation_uuid, (prev_organisation_registrering.registrering).timeperiod, null);

    -- The ordering in as_list (called by as_read) ensures that the latest
    -- registration is returned at index pos 1.

    IF NOT (lower((read_new_organisation.registrering[1].registrering).TimePeriod) = lower((new_organisation_registrering.registrering).TimePeriod) and lower((read_prev_organisation.registrering[1].registrering).TimePeriod)=lower((prev_organisation_registrering.registrering).TimePeriod)) THEN
      RAISE EXCEPTION 'Error updating organisation with id [%]: The ordering of as_list_organisation should ensure that the latest registrering can be found at index 1. Expected new reg: [%]. Actual new reg at index 1: [%]. Expected prev reg: [%]. Actual prev reg at index 1: [%].', organisation_uuid, to_json(new_organisation_registrering), to_json(read_new_organisation.registrering[1].registrering), to_json(prev_organisation_registrering), to_json(prev_new_organisation.registrering[1].registrering) USING ERRCODE = 'MO500';
    END IF;
     
    -- We'll ignore the registreringBase part in the comparrison - except
    -- for the livcykluskode
    read_new_organisation_reg := ROW(
        ROW (null, (read_new_organisation.registrering[1].registrering).livscykluskode, null, null)::registreringBase,
        
        (read_new_organisation.registrering[1]).tilsGyldighed ,
        
        (read_new_organisation.registrering[1]).attrEgenskaber ,
        (read_new_organisation.registrering[1]).relationer
    )::organisationRegistreringType;

    read_prev_organisation_reg := ROW(
        ROW(null, (read_prev_organisation.registrering[1].registrering).livscykluskode, null, null)::registreringBase,
        
        (read_prev_organisation.registrering[1]).tilsGyldighed ,
        
        (read_prev_organisation.registrering[1]).attrEgenskaber ,
        (read_prev_organisation.registrering[1]).relationer
    )::organisationRegistreringType;


    IF read_prev_organisation_reg = read_new_organisation_reg THEN
      --RAISE NOTICE 'Note[%]. Aborted reg:%',note,to_json(read_new_organisation_reg);
      --RAISE NOTICE 'Note[%]. Previous reg:%',note,to_json(read_prev_organisation_reg);
      RAISE EXCEPTION 'Aborted updating organisation with id [%] as the given data, does not give raise to a new registration. Aborted reg:[%], previous reg:[%]', organisation_uuid, to_json(read_new_organisation_reg), to_json(read_prev_organisation_reg) USING ERRCODE = 'MO400';
    END IF;


    return new_organisation_registrering.id;
END; $$ LANGUAGE plpgsql VOLATILE;




